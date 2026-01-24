class AnthropicService
  attr_reader :session

  def initialize(session)
    @session = session
    @client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])
  end

  def send_message(user_message)
    # Add user message to session
    session.add_message("user", user_message)

    # Build messages array
    messages = build_messages

    begin
      # Call Anthropic API
      response = @client.messages(
        parameters: {
          model: "claude-sonnet-4-20250514",
          max_tokens: 4096,
          messages: messages,
          tools: tool_definitions
        }
      )

      # Handle response
      handle_response(response)
    rescue StandardError => e
      Rails.logger.error "Anthropic API error: #{e.message}"
      "I'm sorry, I encountered an error processing your request. Please try again."
    end
  end

  private

  def build_messages(new_message = nil)
    messages = session.messages.map do |msg|
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

  def handle_response(response)
    content = response["content"]

    # Check for tool use
    tool_uses = content.select { |block| block["type"] == "tool_use" }

    if tool_uses.any?
      # Execute tools and get results
      tool_results = tool_uses.map do |tool_use|
        execute_tool(tool_use)
      end

      # Add assistant message with tool calls
      session.add_message("assistant", extract_text(content), tool_uses)

      # Add tool results
      tool_results.each do |result|
        session.add_message("user", result[:content], nil)
      end

      # Make another API call with tool results
      follow_up_response = @client.messages(
        parameters: {
          model: "claude-sonnet-4-20250514",
          max_tokens: 4096,
          messages: build_messages,
          tools: tool_definitions
        }
      )

      # Handle follow-up response
      handle_response(follow_up_response)
    else
      # No tool use, just text response
      text_response = extract_text(content)
      session.add_message("assistant", text_response)
      text_response
    end
  end

  def execute_tool(tool_use)
    executor = ToolExecutor.new(session.user)
    result = executor.execute(tool_use["name"], tool_use["input"])

    {
      type: "tool_result",
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
