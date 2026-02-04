class AnthropicService
  SYSTEM_PROMPT = <<~PROMPT
    You are a helpful gaming backlog assistant. You help users manage their game library
    and decide what to play next. You have access to their backlog data and can provide
    recommendations based on their playing history and preferences.

    Be conversational, enthusiastic about games, and help users make decisions without
    overwhelming them with choices. When recommending games, explain your reasoning briefly.
  PROMPT

  MAX_TOOL_DEPTH = 5

  attr_reader :user, :chat_session

  def initialize(user, chat_session)
    @user = user
    @chat_session = chat_session
    @client = Anthropic::Client.new(
      access_token: ENV["ANTHROPIC_API_KEY"],
      request_timeout: 60
    )
    @tool_executor = ToolExecutor.new(user)
  end

  def send_message(user_message, &block)
    # Add user message to session
    chat_session.add_message("user", user_message)

    # Build messages array
    messages = build_messages

    begin
      if block_given?
        # Streaming mode
        send_message_streaming(messages, &block)
      else
        # Non-streaming mode (for tests)
        response = @client.messages(
          parameters: {
            model: "claude-sonnet-4-5-20250929",
            max_tokens: 4096,
            system: SYSTEM_PROMPT,
            messages: messages,
            tools: tool_definitions
          }
        )
        handle_response(response, 0)
      end
    rescue StandardError => e
      Rails.logger.error "Anthropic API error: #{e.message}"
      error_message = "I'm sorry, I encountered an error processing your request. Please try again."
      block.call({ type: "error", content: error_message }) if block_given?
      error_message
    end
  end

  private

  def send_message_streaming(messages, &block)
    accumulated_text = ""
    tool_uses = []

    @client.messages(
      parameters: {
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 4096,
        system: SYSTEM_PROMPT,
        messages: messages,
        tools: tool_definitions,
        stream: true
      }
    ) do |event|
      case event.event
      when "content_block_start"
        # New content block starting
        if event.content_block && event.content_block["type"] == "tool_use"
          tool_uses << event.content_block
        end
      when "content_block_delta"
        if event.delta["type"] == "text_delta"
          # Stream text chunk
          text_chunk = event.delta["text"]
          accumulated_text += text_chunk
          block.call({ type: "text", content: text_chunk })
        elsif event.delta["type"] == "input_json_delta"
          # Tool input being streamed - accumulate it
          tool_uses.last["input"] ||= ""
          tool_uses.last["input"] += event.delta["partial_json"]
        end
      when "message_stop"
        # Message complete
        if tool_uses.any?
          # Parse tool inputs and execute tools
          tool_uses.each do |tool_use|
            tool_use["input"] = JSON.parse(tool_use["input"]) if tool_use["input"].is_a?(String)
          end

          # Save assistant message with tool calls
          chat_session.add_message("assistant", accumulated_text, tool_uses)

          # Execute tools
          tool_results = tool_uses.map { |tool_use| execute_tool(tool_use) }

          # Add tool results
          tool_result_content = tool_results.map do |result|
            {
              "type" => "tool_result",
              "tool_use_id" => result[:tool_use_id],
              "content" => result[:content]
            }
          end
          chat_session.add_message("user", tool_result_content)

          # Continue conversation with tool results
          send_message_streaming(build_messages, &block)
        else
          # No tool use, save the text response
          chat_session.add_message("assistant", accumulated_text)
          block.call({ type: "done" })
        end
      end
    end
  end

  def build_messages(new_message = nil)
    messages = chat_session.messages.map do |msg|
      {
        "role" => msg["role"],
        "content" => msg["content"]
      }
    end

    if new_message
      messages << {
        "role" => "user",
        "content" => new_message
      }
    end

    messages
  end

  def handle_response(response, depth = 0)
    content = response["content"]

    # Check for tool use
    tool_uses = content.select { |block| block["type"] == "tool_use" }

    if tool_uses.any?
      # Check recursion depth limit
      if depth >= MAX_TOOL_DEPTH
        Rails.logger.warn "Max tool depth (#{MAX_TOOL_DEPTH}) reached, stopping recursion"
        text_response = extract_text(content)
        chat_session.add_message("assistant", text_response.presence || "I've reached my processing limit. Please try again.")
        return text_response.presence || "I've reached my processing limit. Please try again."
      end

      # Execute tools and get results
      tool_results = tool_uses.map do |tool_use|
        execute_tool(tool_use)
      end

      # Add assistant message with tool calls
      chat_session.add_message("assistant", extract_text(content), tool_uses)

      # Build tool result message content
      tool_result_content = tool_results.map do |result|
        {
          "type" => "tool_result",
          "tool_use_id" => result[:tool_use_id],
          "content" => result[:content]
        }
      end

      # Add tool results as user message
      chat_session.add_message("user", tool_result_content)

      # Make another API call with tool results
      follow_up_response = @client.messages(
        parameters: {
          model: "claude-sonnet-4-5-20250929",
          max_tokens: 4096,
          system: SYSTEM_PROMPT,
          messages: build_messages,
          tools: tool_definitions
        }
      )

      # Handle follow-up response with incremented depth
      handle_response(follow_up_response, depth + 1)
    else
      # No tool use, just text response
      text_response = extract_text(content)
      chat_session.add_message("assistant", text_response)
      text_response
    end
  end

  def execute_tool(tool_use)
    result = @tool_executor.execute(tool_use["name"], tool_use["input"])

    {
      tool_use_id: tool_use["id"],
      content: result.to_json
    }
  end

  def extract_text(content)
    text_blocks = content.select { |block| block["type"] == "text" }
    text_blocks.map { |block| block["text"] }.join("\n")
  end

  def tool_definitions
    [
      {
        name: "get_user_backlog",
        description: "Retrieves the user's game backlog with optional filtering by status and limit",
        input_schema: {
          type: "object",
          properties: {
            status: {
              type: "string",
              enum: ["backlog", "playing", "completed", "abandoned", "wishlist"],
              description: "Filter games by status"
            },
            limit: {
              type: "integer",
              description: "Maximum number of games to return (default: 50)"
            }
          }
        }
      },
      {
        name: "search_games",
        description: "Search for games in the IGDB database by name or keyword",
        input_schema: {
          type: "object",
          properties: {
            query: {
              type: "string",
              description: "Search query (game name or keyword)"
            }
          },
          required: ["query"]
        }
      },
      {
        name: "get_game_details",
        description: "Get detailed information about a specific game from IGDB",
        input_schema: {
          type: "object",
          properties: {
            game_id: {
              type: "integer",
              description: "IGDB game ID"
            }
          },
          required: ["game_id"]
        }
      },
      {
        name: "add_to_backlog",
        description: "Add a game to the user's backlog",
        input_schema: {
          type: "object",
          properties: {
            game_id: {
              type: "integer",
              description: "IGDB game ID"
            },
            status: {
              type: "string",
              enum: ["backlog", "playing", "completed", "abandoned", "wishlist"],
              description: "Initial status for the game"
            },
            priority: {
              type: "integer",
              description: "Priority level (1-5)"
            }
          },
          required: ["game_id"]
        }
      },
      {
        name: "update_game_status",
        description: "Update the status, priority, or notes for a game in the user's backlog",
        input_schema: {
          type: "object",
          properties: {
            user_game_id: {
              type: "integer",
              description: "User game ID"
            },
            status: {
              type: "string",
              enum: ["backlog", "playing", "completed", "abandoned", "wishlist"],
              description: "New status"
            },
            priority: {
              type: "integer",
              description: "New priority level (1-5)"
            },
            notes: {
              type: "string",
              description: "Notes about the game"
            }
          },
          required: ["user_game_id"]
        }
      },
      {
        name: "get_recommendations",
        description: "Get personalized game recommendations based on the user's backlog and playing patterns",
        input_schema: {
          type: "object",
          properties: {
            count: {
              type: "integer",
              description: "Number of recommendations to return (default: 5)"
            }
          }
        }
      }
    ]
  end
end
