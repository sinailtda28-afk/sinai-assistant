import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input"]
  static values = { url: String }

  connect() {
    this.displayTarget.addEventListener("click", () => this.edit())
    this.inputTarget.addEventListener("blur", () => this.save())
    this.inputTarget.addEventListener("keydown", (e) => {
      if (e.key === "Enter") this.save()
      if (e.key === "Escape") this.cancel()
    })
  }

  edit() {
    this.displayTarget.style.display = "none"
    this.formTarget.style.display = "inline"
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  save() {
    const form = this.formTarget.closest("form")
    const formData = new FormData(form)
    formData.append("_method", "patch")

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: formData
    }).then(response => {
      if (response.ok) {
        this.displayTarget.textContent = this.inputTarget.value
        this.displayTarget.style.display = "inline"
        this.formTarget.style.display = "none"
      }
    }).catch(() => {
      this.cancel()
    })
  }

  cancel() {
    this.inputTarget.value = this.displayTarget.textContent.trim()
    this.displayTarget.style.display = "inline"
    this.formTarget.style.display = "none"
  }
}
