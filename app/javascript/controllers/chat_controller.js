import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "form"]
  static values = { sessionId: String }

  connect() {
    console.log("Chat controller connected")
    this.scrollToBottom()
  }

  async submit(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message) return

    // Add user message to UI
    this.addMessage("user", message)
    this.inputTarget.value = ""
    this.inputTarget.disabled = true

    try {
      // Send to server
      const response = await this.sendMessage(message)

      // Add assistant response
      this.addMessage("assistant", response.response)

      // Update session ID
      this.sessionIdValue = response.session_id

    } catch (error) {
      console.error("Chat error:", error)
      this.addMessage("system", "Sorry, something went wrong. Please try again.")
    } finally {
      this.inputTarget.disabled = false
      this.inputTarget.focus()
    }
  }

  async sendMessage(message) {
    const url = "/chat/messages"
    const body = { message }

    if (this.sessionIdValue) {
      body.session_id = this.sessionIdValue
    }

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify(body)
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    return await response.json()
  }

  addMessage(role, content) {
    const messageDiv = document.createElement("div")
    messageDiv.classList.add("message", `message-${role}`)

    const contentDiv = document.createElement("div")
    contentDiv.classList.add("message-content")
    contentDiv.textContent = content

    messageDiv.appendChild(contentDiv)
    this.messagesTarget.appendChild(messageDiv)

    this.scrollToBottom()
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
