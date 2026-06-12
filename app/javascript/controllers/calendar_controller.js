import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "title", "priority", "tags", "desc", "dateDisplay", "dateInput"]

  connect() {
    if (this.hasModalTarget) {
      this.modalTarget.addEventListener("click", (e) => {
        if (e.target === this.modalTarget) this.closeModal()
      })
    }
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && this.modalTarget && this.modalTarget.style.display !== "none") this.closeModal()
    })
  }

  openModal(event) {
    const dayEl = event.currentTarget.closest("[data-date]")
    if (!dayEl) return
    const date = dayEl.dataset.date
    this.dateInputTarget.value = date
    this.dateDisplayTarget.textContent = this.formatDate(date)
    this.titleTarget.value = ""
    this.modalTarget.style.display = "flex"
    this.titleTarget.focus()
  }

  closeModal() {
    this.modalTarget.style.display = "none"
  }

  createTask(event) {
    event.preventDefault()
    const title = this.titleTarget.value.trim()
    if (!title) return

    const btn = event.target.querySelector("button[type=submit]")
    if (btn) btn.disabled = true

    const data = new FormData()
    data.set("task[title]", title)
    data.set("task[due_date]", this.dateInputTarget.value)
    data.set("task[priority]", this.priorityTarget.value)
    data.set("task[column_id]", this.element.dataset.defaultColumn || "")

    const desc = this.descTarget.value.trim()
    if (desc) data.set("task[description]", desc)

    const rawTags = this.tagsTarget.value || ""
    rawTags.split(",").map(t => t.trim()).filter(t => t).forEach(t => data.append("task[tags][]", t))

    fetch("/tasks.json", {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrf() },
      body: data
    }).then(r => r.json()).then(() => {
      this.closeModal()
      const dayEl = document.querySelector(`[data-date="${this.dateInputTarget.value}"]`)
      if (dayEl) {
        const indicator = dayEl.querySelector(".calendar-event-indicator")
        if (indicator) {
          indicator.textContent = parseInt(indicator.textContent || "0") + 1
        } else {
          const dot = document.createElement("span")
          dot.className = "calendar-event-indicator"
          dot.style.cssText = "display:inline-block;background:#3b82f6;color:#fff;border-radius:50%;width:18px;height:18px;text-align:center;font-size:0.65rem;line-height:18px;margin:1px"
          dot.textContent = "1"
          const cell = dayEl.querySelector(".calendar-day")
          if (cell) cell.appendChild(dot)
        }
      }
    }).catch(() => {
      alert("Erro ao criar tarefa")
    }).finally(() => {
      if (btn) btn.disabled = false
    })
  }

  formatDate(dateStr) {
    const parts = dateStr.split("-")
    return `${parts[2]}/${parts[1]}/${parts[0]}`
  }

  csrf() {
    return document.querySelector("[name='csrf-token']")?.content || ""
  }
}
