import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["column"]

  connect() {
    this.sortables = this.columnTargets.map(column => {
      return new Sortable(column, {
        group: "kanban",
        animation: 150,
        ghostClass: "sortable-ghost",
        onEnd: this.onEnd.bind(this)
      })
    })
  }

  disconnect() {
    if (this.sortables) {
      this.sortables.forEach(s => s.destroy())
    }
  }

  onEnd(event) {
    const taskId = event.item.dataset.taskId
    const toColumnId = event.to.closest("[data-column-id]").dataset.columnId
    const position = event.newIndex

    if (event.from !== event.to) {
      fetch(`/tasks/${taskId}/move`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ to_column_id: toColumnId, position: position })
      }).catch(error => console.error("Move failed:", error))
    }
  }
}
