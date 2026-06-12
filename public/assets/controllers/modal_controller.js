import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    this.overlayTarget.addEventListener("click", (e) => {
      if (e.target === this.overlayTarget) this.close()
    })
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") this.close()
    })
  }

  open() {
    this.overlayTarget.style.display = "flex"
  }

  close() {
    this.overlayTarget.style.display = "none"
  }
}
