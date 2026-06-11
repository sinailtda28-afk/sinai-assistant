import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "color", "id"]

  open(event) {
    const columnCard = event.currentTarget.closest("[data-column-id]")
    this.idTarget.value = columnCard.dataset.columnId
    this.nameTarget.value = columnCard.querySelector("h3").textContent.replace(/\(\d+\)$/, "").trim()
    this.colorTarget.value = columnCard.style.borderTopColor || "#6b7280"
  }

  save(event) {
    event.preventDefault()
    const form = event.currentTarget
    const formData = new FormData(form)

    fetch(`/columns/${this.idTarget.value}`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        "Accept": "text/html"
      },
      body: new URLSearchParams(formData)
    }).then(response => {
      if (response.ok) {
        window.location.reload()
      }
    })
  }
}
