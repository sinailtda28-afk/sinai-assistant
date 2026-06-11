import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editForm", "cardContent", "newForm"]

  edit(event) {
    event.preventDefault()
    const card = event.target.closest(".task-card")
    const cardContent = card.querySelector("[data-task-form-target='cardContent']")
    const editForm = card.querySelector("[data-task-form-target='editForm']")
    if (cardContent) cardContent.style.display = "none"
    if (editForm) editForm.style.display = "block"
  }

  cancel(event) {
    event.preventDefault()
    const card = event.target.closest(".task-card")
    const cardContent = card.querySelector("[data-task-form-target='cardContent']")
    const editForm = card.querySelector("[data-task-form-target='editForm']")
    if (cardContent) cardContent.style.display = "block"
    if (editForm) editForm.style.display = "none"
  }

  openNewForm(event) {
    event.preventDefault()
    const newForm = this.newFormTarget
    if (newForm) {
      newForm.style.display = "block"
      const titleInput = newForm.querySelector("input[name='task[title]']")
      if (titleInput) titleInput.focus()
    }
  }

  closeNewForm(event) {
    event.preventDefault()
    const newForm = this.newFormTarget
    if (newForm) newForm.style.display = "none"
  }

  submitEnd(event) {
    if (event.detail.success) {
      const newForm = this.newFormTarget
      if (newForm) {
        newForm.style.display = "none"
        newForm.querySelectorAll("input, textarea, select").forEach(el => el.value = "")
      }
    }
  }
}
