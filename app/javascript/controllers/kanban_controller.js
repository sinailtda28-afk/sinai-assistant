import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["taskModal", "columnModal", "editColumnModal", "board",
                    "taskTitle", "taskDesc", "taskDue", "taskPriority", "taskTags", "taskColumn",
                    "colName", "colColor", "editColId", "editColName", "editColColor",
                    "priorityFilter", "tagFilter", "aiChat", "qrModal",
                    "wppModal", "wppNumber", "wppMessage", "wppInstance",
                    "taskFiles", "taskLink"]

  connect() {
    this.initTaskSortable()
    this.initColumnSortable()
    this.bindModals()
    this._creating = false
    document.addEventListener("keydown", (e) => { if (e.key === "Escape") this.closeAll() })
  }

  initTaskSortable() {
    this.boardTarget.querySelectorAll(".kanban-tasks").forEach(el => {
      Sortable.create(el, {
        group: "tasks", animation: 150, ghostClass: "sortable-ghost",
        onEnd: (evt) => this.handleDragEnd(evt)
      })
    })
  }

  initColumnSortable() {
    Sortable.create(this.boardTarget, {
      animation: 200, handle: "h3",
      onEnd: (evt) => this.handleColumnDragEnd(evt)
    })
  }

  bindModals() {
    [this.taskModalTarget, this.columnModalTarget, this.editColumnModalTarget, this.qrModalTarget].forEach(el => {
      if (!el) return
      el.addEventListener("click", (e) => { if (e.target === el) this.closeAll() })
    })
  }

  /* ───── Modals ───── */
  openModal() { this.taskModalTarget.style.display = "flex"; this.taskTitleTarget.focus() }
  closeTaskModal() { this.taskModalTarget.style.display = "none"; this.resetTaskForm() }
  openColumnModal() { this.columnModalTarget.style.display = "flex"; this.colNameTarget.focus() }
  closeColumnModal() { this.columnModalTarget.style.display = "none" }
  closeAll() {
    if (this.hasTaskModalTarget) this.taskModalTarget.style.display = "none"
    if (this.hasColumnModalTarget) this.columnModalTarget.style.display = "none"
    if (this.hasEditColumnModalTarget) this.editColumnModalTarget.style.display = "none"
  }

  openEditColumn(event) {
    const col = event.currentTarget.closest("[data-column-id]")
    this.editColIdTarget.value = col.dataset.columnId
    this.editColNameTarget.value = col.querySelector("h3").textContent.replace(/\s*\(\d+\)\s*/, "").trim()
    this.editColColorTarget.value = col.style.borderTopColor || "#6b7280"
    this.editColumnModalTarget.style.display = "flex"
  }
  closeEditColumnModal() { this.editColumnModalTarget.style.display = "none" }

  /* ───── Task CRUD ───── */
  createTask(event) {
    event.preventDefault()
    const form = event.target
    if (!this.taskTitleTarget.value.trim() || this._creating) return
    this._creating = true
    const btn = form.querySelector("input[type=submit]")
    if (btn) { btn.disabled = true; btn.value = "Criando..." }

    const data = new FormData()
    data.set("task[title]", this.taskTitleTarget.value)
    data.set("task[description]", this.taskDescTarget.value || "")
    data.set("task[due_date]", this.taskDueTarget.value || "")
    data.set("task[priority]", this.taskPriorityTarget.value || "medium")
    data.set("task[column_id]", this.taskColumnTarget.value || "")

    const tagValue = this.taskTagsTarget.value || ""
    tagValue.split(",").map(t => t.trim()).filter(t => t).forEach(t => data.append("task[tags][]", t))

    if (this.hasTaskLinkTarget) data.set("task[link]", this.taskLinkTarget.value || "")
    if (this.hasTaskFilesTarget) {
      Array.from(this.taskFilesTarget.files).forEach(f => data.append("task[files][]", f))
    }

    fetch("/tasks.json", {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrf() },
      body: data
    }).then(r => r.json()).then(task => {
      const col = this.boardTarget.querySelector(`[data-column-id="${task.column_id}"] .kanban-tasks`)
      if (col) col.insertAdjacentHTML("beforeend", this.taskCardHtml(task))
      this.closeTaskModal()
      this.initTaskSortable()
      this.updateCounts()
    }).finally(() => {
      this._creating = false
      if (btn) { btn.disabled = false; btn.value = "Criar" }
    })
  }

  resetTaskForm() {
    if (this.hasTaskTitleTarget) this.taskTitleTarget.value = ""
    if (this.hasTaskDescTarget) this.taskDescTarget.value = ""
    if (this.hasTaskDueTarget) this.taskDueTarget.value = ""
    if (this.hasTaskTagsTarget) this.taskTagsTarget.value = ""
  }

  expandInlineForm(event) {
    const wrapper = event.target.closest(".inline-task-form")
    if (wrapper.querySelector(".inline-expanded-form")) return
    const originalInput = wrapper.querySelector("input")
    const columnId = wrapper.closest("[data-column-id]").dataset.columnId
    const today = new Date().toISOString().split("T")[0]

    const form = document.createElement("div")
    form.className = "inline-expanded-form"
    form.style.cssText = "padding:0.5rem;display:flex;flex-direction:column;gap:0.4rem"
    form.innerHTML = `
      <input type="text" class="inline-title" placeholder="Titulo da tarefa" style="width:100%;padding:6px 8px;border:1px solid #d1d5db;border-radius:4px;font-size:0.8rem;background:var(--card-bg);color:var(--text)" autofocus>
      <textarea class="inline-note" placeholder="Nota (opcional)" rows="2" style="width:100%;padding:4px 6px;border:1px solid #d1d5db;border-radius:4px;font-size:0.75rem;background:var(--card-bg);color:var(--text);resize:none"></textarea>
      <input type="text" class="inline-tags" placeholder="Tags: trabalho, pessoal" style="width:100%;padding:4px 6px;border:1px solid #d1d5db;border-radius:4px;font-size:0.75rem;background:var(--card-bg);color:var(--text)">
      <input type="date" class="inline-due" value="" placeholder="Prazo" style="width:100%;padding:4px 6px;border:1px solid #d1d5db;border-radius:4px;font-size:0.75rem;background:var(--card-bg);color:var(--text)">
      <input type="text" class="inline-comment" placeholder="Comentario (opcional)" style="width:100%;padding:4px 6px;border:1px solid #d1d5db;border-radius:4px;font-size:0.75rem;background:var(--card-bg);color:var(--text)">
      <div style="display:flex;gap:0.3rem;justify-content:flex-end">
        <button class="btn btn-sm btn-secondary" data-action="cancel-inline" style="font-size:0.7rem;padding:2px 8px">Cancelar</button>
        <button class="btn btn-sm btn-primary" data-action="submit-inline" style="font-size:0.7rem;padding:2px 8px">Criar</button>
      </div>
    `
    form.querySelector("[data-action='submit-inline']").addEventListener("click", (e) => {
      e.preventDefault()
      this.submitInlineForm(form, columnId)
    })
    form.querySelector("[data-action='cancel-inline']").addEventListener("click", () => {
      form.remove()
    })
    form.querySelector(".inline-title").addEventListener("keydown", (e) => {
      if (e.key === "Escape") form.remove()
    })
    form.querySelectorAll("input, textarea").forEach(el => {
      el.addEventListener("keydown", (e) => {
        if (e.key === "Enter" && !e.shiftKey && el.tagName !== "TEXTAREA") {
          e.preventDefault()
          this.submitInlineForm(form, columnId)
        }
      })
    })

    wrapper.appendChild(form)
    form.querySelector(".inline-title").focus()
  }

  submitInlineForm(form, columnId) {
    const title = form.querySelector(".inline-title").value.trim()
    if (!title || this._creating) return
    this._creating = true

    const data = new FormData()
    data.set("task[title]", title)
    data.set("task[column_id]", columnId)
    data.set("task[priority]", "medium")
    data.set("task[description]", form.querySelector(".inline-note").value || "")
    data.set("task[due_date]", form.querySelector(".inline-due").value || "")
    data.set("task[inline_comment]", form.querySelector(".inline-comment").value || "")

    const rawTags = form.querySelector(".inline-tags").value || ""
    rawTags.split(",").map(t => t.trim()).filter(t => t).forEach(t => data.append("task[tags][]", t))

    fetch("/tasks.json", {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrf(), "X-Inline-Comment": form.querySelector(".inline-comment").value },
      body: data
    }).then(r => r.json()).then(task => {
      const col = this.boardTarget.querySelector(`[data-column-id="${columnId}"] .kanban-tasks`)
      if (col) col.insertAdjacentHTML("beforeend", this.taskCardHtml(task))
      form.remove()
      this.initTaskSortable()
      this.updateCounts()
    }).finally(() => { this._creating = false })
  }

  inlineCreateTask(event) {
    event.preventDefault()
    this.expandInlineForm(event)
  }

  completeTask(event) {
    const id = event.currentTarget.dataset.taskId
    const card = event.currentTarget.closest(".task-card")
    fetch(`/tasks/${id}`, {
      method: "PATCH",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json" },
      body: new URLSearchParams({ "task[completed_at]": new Date().toISOString() })
    }).then(r => r.json()).then(task => {
      card.classList.add("completed-task")
      setTimeout(() => { card.remove(); this.updateCounts() }, 400)
    })
  }

  deleteTask(event) {
    const id = event.currentTarget.dataset.taskId
    const card = event.currentTarget.closest(".task-card")
    if (!confirm("Excluir esta tarefa?")) return
    fetch(`/tasks/${id}`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": this.csrf(), "Accept": "application/json" }
    }).then(() => { card.remove(); this.updateCounts() })
  }

  updatePriority(event) {
    const id = event.target.dataset.taskId
    const priority = event.target.value
    fetch(`/tasks/${id}`, {
      method: "PATCH",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json" },
      body: new URLSearchParams({ "task[priority]": priority })
    })
    event.target.className = `priority-chip priority-${priority}`
  }

  editTaskTitle(event) {
    const target = event.currentTarget
    const id = target.dataset.taskId
    const current = target.textContent
    const input = document.createElement("input")
    input.value = current
    input.style.cssText = "width:100%;padding:2px 4px;border:2px solid #3b82f6;border-radius:3px;font-size:0.9rem"
    input.addEventListener("blur", () => this.saveTaskTitle(id, input.value, target, input))
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") this.saveTaskTitle(id, input.value, target, input)
      if (e.key === "Escape") input.remove()
    })
    target.replaceWith(input)
    input.focus(); input.select()
  }

  saveTaskTitle(id, title, original, input) {
    if (!title.trim()) { input.replaceWith(original); return }
    fetch(`/tasks/${id}`, {
      method: "PATCH",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json" },
      body: new URLSearchParams({ "task[title]": title })
    }).then(() => {
      original.textContent = title
      input.replaceWith(original)
    })
  }

  editTaskDescription(event) {
    const target = event.currentTarget
    const id = target.dataset.taskId
    const current = target.textContent === "+ Nota" ? "" : target.textContent
    const textarea = document.createElement("textarea")
    textarea.value = current
    textarea.style.cssText = "width:100%;padding:4px 6px;border:2px solid #3b82f6;border-radius:4px;font-size:0.75rem;resize:none;height:60px;background:var(--card-bg);color:var(--text)"
    textarea.addEventListener("blur", () => this.saveTaskDesc(id, textarea.value, target, textarea))
    textarea.addEventListener("keydown", (e) => {
      if (e.key === "Escape") { textarea.value = current; textarea.blur() }
    })
    target.replaceWith(textarea)
    textarea.focus()
  }

  saveTaskDesc(id, description, original, textarea) {
    fetch(`/tasks/${id}`, {
      method: "PATCH",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json" },
      body: new URLSearchParams({ "task[description]": description })
    }).then(() => {
      const desc = description ? this.escapeHtml(description).substring(0, 80) : null
      if (desc) {
        original.textContent = this.escapeHtml(description).substring(0, 80)
        original.style.color = "var(--text-secondary)"
      } else {
        original.textContent = "+ Nota"
        original.style.color = "#9ca3af"
      }
      textarea.replaceWith(original)
    })
  }

  /* ───── Column CRUD ───── */
  createColumn(event) {
    event.preventDefault()
    const name = this.colNameTarget.value.trim()
    if (!name || this._creating) return
    this._creating = true
    const btn = this.colNameTarget.closest("form").querySelector("input[type=submit]")
    if (btn) btn.disabled = true

    fetch("/columns.json", {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ "column[name]": name, "column[color]": this.colColorTarget.value })
    }).then(r => r.json()).then(col => {
      this.boardTarget.insertAdjacentHTML("beforeend", this.columnHtml(col))
      this.closeColumnModal()
      this.initTaskSortable()
      this.initColumnSortable()
    }).finally(() => {
      this._creating = false
      if (btn) btn.disabled = false
    })
  }

  updateColumn(event) {
    event.preventDefault()
    const id = this.editColIdTarget.value
    const name = this.editColNameTarget.value.trim()
    if (!name) return
    const btn = event.target.querySelector("button[type=submit]")
    if (btn) btn.disabled = true

    fetch(`/columns/${id}.json`, {
      method: "PATCH",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ "column[name]": name, "column[color]": this.editColColorTarget.value })
    }).then(r => r.json()).then(col => {
      const el = this.boardTarget.querySelector(`[data-column-id="${col.id}"]`)
      if (el) {
        el.querySelector("h3").childNodes[0].textContent = col.name + " "
        el.style.borderTopColor = col.color
      }
      this.closeEditColumnModal()
    }).finally(() => { if (btn) btn.disabled = false })
  }

  deleteColumn(event) {
    const id = this.editColIdTarget.value
    if (!confirm("Excluir coluna e todas as tarefas? Nao pode ser desfeita.")) return
    fetch(`/columns/${id}`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": this.csrf(), "Accept": "application/json" }
    }).then(() => {
      const el = this.boardTarget.querySelector(`[data-column-id="${id}"]`)
      if (el) el.remove()
      this.closeEditColumnModal()
      this.updateCounts()
    })
  }

  /* ───── Drag & Drop ───── */
  handleDragEnd(evt) {
    const taskId = evt.item.dataset.taskId
    const columnId = evt.to.dataset.columnId
    if (!taskId || !columnId) return
    fetch(`/tasks/${taskId}/move`, {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ to_column_id: columnId, position: evt.newIndex })
    }).then(() => this.updateCounts())
  }

  handleColumnDragEnd(evt) {
    const cols = this.boardTarget.querySelectorAll("[data-column-id]")
    cols.forEach((col, i) => {
      fetch(`/columns/${col.dataset.columnId}`, {
        method: "PATCH",
        headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json" },
        body: new URLSearchParams({ "column[position]": i, "column[name]": col.querySelector("h3").textContent.replace(/\s*\(\d+\)\s*/, "").trim() })
      })
    })
  }

  /* ───── Tags ───── */
  addTag(event) {
    event.preventDefault()
    const taskId = event.currentTarget.dataset.taskId
    const input = event.currentTarget.closest(".tag-adder").querySelector("input")
    const name = input.value.trim()
    if (!name) return

    fetch(`/tasks/${taskId}`, {
      method: "PATCH",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json" },
      body: new URLSearchParams({ "task[tags][]": name })
    }).then(r => r.json()).then(task => {
      const meta = event.currentTarget.closest(".task-card").querySelector(".task-meta")
      const pills = meta.querySelectorAll(".tag-pill")
      pills.forEach(p => p.remove())
      task.tags.forEach(t => {
        meta.insertAdjacentHTML("beforeend", `<a href="/?tag=${t.name}" class="tag-pill">${t.name}</a>`)
      })
      this.refreshTagFilter()
    })
    input.value = ""
  }

  refreshTagFilter() {
    fetch("/tags.json", { headers: { "Accept": "application/json" } }).then(r => r.json()).then(tags => {
      if (!this.hasTagFilterTarget) return
      const current = this.tagFilterTarget.value
      this.tagFilterTarget.innerHTML = '<option value="">Todas</option>'
      tags.forEach(t => {
        this.tagFilterTarget.innerHTML += `<option value="${t.name}" ${t.name === current ? 'selected' : ''}>${t.name}</option>`
      })
    })
  }

  /* ───── Filters ───── */
  filter() {
    const params = new URLSearchParams()
    if (this.priorityFilterTarget.value) params.set("priority", this.priorityFilterTarget.value)
    if (this.tagFilterTarget.value) params.set("tag", this.tagFilterTarget.value)
    window.location.search = params.toString()
  }

  filterToday() {
    const today = new Date().toISOString().split("T")[0]
    window.location.search = new URLSearchParams({ start_date: today, end_date: today }).toString()
  }

  filterWeek() {
    const now = new Date()
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay()).toISOString().split("T")[0]
    const end = new Date(now.getFullYear(), now.getMonth(), now.getDate() + (6 - now.getDay())).toISOString().split("T")[0]
    window.location.search = new URLSearchParams({ start_date: start, end_date: end }).toString()
  }

  filterMonth() {
    const now = new Date()
    const start = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split("T")[0]
    const end = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().split("T")[0]
    window.location.search = new URLSearchParams({ start_date: start, end_date: end }).toString()
  }

  /* ───── AI Chat ───── */
  toggleAIChat() {
    const sidebar = document.getElementById("ai-chat-sidebar")
    const isHidden = sidebar.style.display === "none" || !sidebar.style.display
    sidebar.style.display = isHidden ? "flex" : "none"
    sidebar.style.flexDirection = "column"
    if (isHidden && !sidebar.dataset.loaded) {
      sidebar.dataset.loaded = "1"
      this.aiAddMessage("assistant", "Ola! Sou seu assistente de produtividade. Pergunte sobre suas tarefas, prazos ou peca analises.")
    }
  }

  aiSend() {
    const input = document.getElementById("ai-input")
    const msg = input.value.trim()
    if (!msg) return
    this.aiAddMessage("user", msg)
    input.value = ""
    input.disabled = true

    fetch("/chat/ask", {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ message: msg })
    }).then(r => r.json()).then(data => {
      this.aiAddMessage("assistant", data.reply || data.error || "Erro ao processar")
    }).finally(() => { input.disabled = false; input.focus() })
  }

  aiAddMessage(role, text) {
    const container = document.getElementById("ai-messages")
    if (!container) return
    const div = document.createElement("div")
    div.style.cssText = `margin-bottom:10px;padding:8px 12px;border-radius:8px;max-width:90%;font-size:0.85rem;${
      role === "user" ? "background:#3b82f6;color:white;align-self:flex-end;margin-left:auto" : "background:#2a2a4a;color:#ddd"
    }`
    div.textContent = text
    container.appendChild(div)
    container.scrollTop = container.scrollHeight
  }

  aiOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.aiSend()
    }
  }

  /* ───── WhatsApp ───── */
  openWppModal(event) {
    const title = event.currentTarget.dataset.taskTitle
    this._wppTaskId = event.currentTarget.dataset.taskId
    this.wppModalTarget.style.display = "flex"
    this.wppNumberTarget.focus()
    if (title && this.hasWppMessageTarget) this.wppMessageTarget.value = `Ola! Tudo bem? Sobre: ${title}`
    this.loadWppInstances()
  }

  closeWppModal() { this.wppModalTarget.style.display = "none" }

  loadWppInstances() {
    const sel = this.wppInstanceTarget
    sel.innerHTML = '<option value="default">Default</option>'

    fetch("/whatsapp/instances", { headers: { "Accept": "application/json" } })
      .then(r => r.json()).then(instances => {
        sel.innerHTML = ""
        if (instances && instances.length > 0) {
          instances.forEach(i => {
            sel.innerHTML += `<option value="${i.name}" ${i.connected ? '' : 'disabled'}>${i.name}${i.connected ? '' : ' (offline)'}</option>`
          })
        } else {
          sel.innerHTML = '<option value="default">Default</option>'
        }
      }).catch(() => {
        sel.innerHTML = '<option value="default">Default</option>'
      })
  }

  generateWppMessage() {
    const taskId = this._wppTaskId
    const number = this.wppNumberTarget.value
    if (!taskId) return

    fetch("/whatsapp/generate_message", {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ task_id: taskId, number: number, context: "" })
    }).then(r => r.json()).then(data => {
      if (data.message) this.wppMessageTarget.value = data.message
    })
  }

  sendWpp() {
    const instance = this.wppInstanceTarget.value || "default"
    const number = this.wppNumberTarget.value.trim()
    const message = this.wppMessageTarget.value.trim()
    if (!number || !message) { alert("Preencha numero e mensagem"); return }

    fetch("/whatsapp/send", {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ instance, number, message })
    }).then(r => r.json()).then(data => {
      if (data.success) {
        alert("Mensagem enviada!")
        this.closeWppModal()
      } else {
        alert("Erro: " + (data.error || "Falha ao enviar"))
      }
    })
  }

  wppNumberOnEnter(event) {
    if (event.key === "Enter") this.wppMessageTarget.focus()
  }

  /* ───── WhatsApp QR Code ───── */
  showWppQr() {
    this.qrModalTarget.style.display = "flex"
    this.fetchQr()
    this._qrInterval = setInterval(() => this.fetchQr(), 5000)
  }

  closeQrModal() {
    this.qrModalTarget.style.display = "none"
    if (this._qrInterval) { clearInterval(this._qrInterval); this._qrInterval = null }
  }

  refreshQr() {
    fetch("/whatsapp/reconnect", {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({})
    }).then(r => r.json()).then(data => {
      const status = document.getElementById("qr-status")
      if (status) {
        status.textContent = data.message || "Reconectando..."
        status.style.color = "#f59e0b"
      }
      const img = document.getElementById("qr-image")
      if (img) { img.src = ""; img.style.display = "none" }
      setTimeout(() => this.fetchQr(), 3000)
    }).catch(() => this.fetchQr())
  }

  fetchQr() {
    fetch("/whatsapp/qrcode", { headers: { "Accept": "application/json" } })
      .then(r => r.json()).then(data => {
        const img = document.getElementById("qr-image")
        const status = document.getElementById("qr-status")
        if (!img || !status) return
        if (data.connected) {
          status.textContent = "✅ WhatsApp conectado!"
          status.style.color = "#10b981"
          img.style.display = "none"
          if (this._qrInterval) { clearInterval(this._qrInterval); this._qrInterval = null }
        } else if (data.qrcode) {
          status.textContent = "Escaneie o QR code abaixo:"
          status.style.color = "var(--text-secondary)"
          img.src = data.qrcode
          img.style.display = "block"
          img.onerror = () => { status.textContent = "Erro ao carregar QR. Tente atualizar."; status.style.color = "#ef4444" }
        } else {
          status.textContent = data.message || data.error || "Aguardando QR code..."
          status.style.color = "#f59e0b"
        }
      }).catch(() => {
        const status = document.getElementById("qr-status")
        if (status) status.textContent = "Erro ao conectar com servidor WhatsApp"
      })
  }

  /* ───── Comments ───── */
  addComment(event) {
    event.preventDefault()
    const taskId = event.currentTarget.dataset.taskId
    const input = event.currentTarget.closest(".comment-form").querySelector("input")
    const content = input.value.trim()
    if (!content) return
    fetch(`/tasks/${taskId}/comments`, {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrf(), "Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json" },
      body: new URLSearchParams({ content })
    }).then(r => r.json()).then(c => {
      const list = event.currentTarget.closest(".task-card").querySelector(".comments-list")
      if (list) {
        list.insertAdjacentHTML("beforeend", `<div style="font-size:0.7rem;color:var(--text-secondary);padding:2px 0;border-top:1px solid #eee">${this.escapeHtml(c.content)} <span style="color:#9ca3af;font-size:0.65rem">${c.created_at}</span></div>`)
      }
      input.value = ""
    })
  }

  commentOnEnter(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.addComment(event)
    }
  }

  /* ───── File Upload ───── */
  attachFile(event) {
    const taskId = event.currentTarget.dataset.taskId
    const input = document.createElement("input")
    input.type = "file"
    input.multiple = true
    input.onchange = () => {
      const data = new FormData()
      Array.from(input.files).forEach(f => data.append("task[files][]", f))
      fetch(`/tasks/${taskId}`, {
        method: "PATCH",
        headers: { "X-CSRF-Token": this.csrf() },
        body: data
      }).then(r => r.json()).then(task => {
        const card = event.currentTarget.closest(".task-card")
        const existingPreviews = card.querySelector(".files-preview")
        if (existingPreviews) existingPreviews.innerHTML = ""
        const previews = document.createElement("div")
        previews.className = "files-preview"
        previews.style.cssText = "margin-top:4px"
        ;(task.files || []).forEach(f => {
          if (f.url && f.url.match(/\.(jpg|jpeg|png|gif|webp|svg)/i)) {
            previews.insertAdjacentHTML("beforeend", `<div style="margin-top:4px"><img src="${f.url}" style="max-width:100%;max-height:80px;border-radius:4px" alt="${f.name}"></div>`)
          } else {
            previews.insertAdjacentHTML("beforeend", `<a href="${f.url}" target="_blank" style="font-size:0.7rem;display:inline-block;margin-top:2px;color:#6b7280">&#128206; ${f.name}</a>`)
          }
        })
        if (existingPreviews) {
          existingPreviews.replaceWith(previews)
        } else {
          const meta = card.querySelector(".task-meta")
          if (meta) meta.before(previews)
          else card.appendChild(previews)
        }
      })
    }
    input.click()
  }

  /* ───── Utils ───── */
  csrf() { return document.querySelector("[name='csrf-token']")?.content || "" }

  updateCounts() {
    this.boardTarget.querySelectorAll(".kanban-column").forEach(col => {
      const count = col.querySelector(".kanban-tasks").children.length
      const badge = col.querySelector(".task-count")
      if (badge) badge.textContent = count
    })
  }

  taskCardHtml(task) {
    const tags = (task.tags || []).map(t => `<a href="/?tag=${t.name}" class="tag-pill">${t.name}</a>`).join("")
    const due = task.due_date ? `<span class="due-date">${task.due_date}</span>` : ""
    const created = task.created_at ? `<span class="created-date" style="font-size:0.65rem;color:#9ca3af">${task.created_at}</span>` : ""
    const desc = task.description ? `<div class="task-note" data-action="click->kanban#editTaskDescription" data-task-id="${task.id}" style="font-size:0.75rem;color:var(--text-secondary);margin:0.2rem 0;cursor:text">${this.escapeHtml(task.description).substring(0, 80)}</div>` : `<div class="task-note" data-action="click->kanban#editTaskDescription" data-task-id="${task.id}" style="font-size:0.75rem;color:#9ca3af;margin:0.2rem 0;cursor:text">+ Nota</div>`
    const link = task.link ? `<a href="${this.escapeHtml(task.link)}" target="_blank" class="task-link" style="font-size:0.7rem;color:#3b82f6;display:inline-block;margin-top:2px">&#128279; Link</a>` : ""
    const files = (task.files || []).map(f => {
      if (f.url && f.url.match(/\.(jpg|jpeg|png|gif|webp|svg)/i)) {
        return `<div style="margin-top:4px"><img src="${f.url}" style="max-width:100%;max-height:80px;border-radius:4px" alt="${f.name}"></div>`
      }
      return `<a href="${f.url}" target="_blank" style="font-size:0.7rem;display:inline-block;margin-top:2px;color:#6b7280">&#128206; ${f.name}</a>`
    }).join("")
    const commentsHtml = (task.comments || []).slice(-2).map(c => `<div style="font-size:0.7rem;color:var(--text-secondary);padding:2px 0;border-top:1px solid #eee">${this.escapeHtml(c.content).substring(0,60)}</div>`).join("")
    return `<div class="task-card" data-task-id="${task.id}" style="border-left:3px solid ${task.column_color || '#6b7280'}">
      <div>
        <strong data-action="dblclick->kanban#editTaskTitle" data-task-id="${task.id}">${this.escapeHtml(task.title)}</strong>
      </div>
      ${desc}
      ${link}
      ${files}
      ${commentsHtml}
      <div class="task-meta">
        ${due}
        ${created}
        <select class="priority-chip priority-${task.priority}" data-task-id="${task.id}" data-action="change->kanban#updatePriority" style="font-size:0.7rem;padding:0.1rem 0.3rem;border:none;border-radius:4px;cursor:pointer">
          <option value="low" ${task.priority === 'low' ? 'selected' : ''}>Baixa</option>
          <option value="medium" ${task.priority === 'medium' ? 'selected' : ''}>Media</option>
          <option value="high" ${task.priority === 'high' ? 'selected' : ''}>Alta</option>
        </select>
        ${tags}
        <span class="tag-adder" style="display:none">
          <input type="text" placeholder="+ tag" style="width:60px;font-size:0.7rem;padding:1px 3px;border:1px solid #d1d5db;border-radius:3px" data-action="keydown->kanban#addTagOnEnter">
          <button data-action="kanban#addTag" data-task-id="${task.id}" style="font-size:0.65rem;background:#e0e7ff;border:none;border-radius:3px;cursor:pointer">+</button>
        </span>
      </div>
      <div class="task-actions">
        <button class="btn-wpp" data-action="kanban#openWppModal" data-task-id="${task.id}" data-task-title="${this.escapeHtml(task.title)}" title="Enviar WhatsApp">&#128172;</button>
        <button class="btn-file" data-action="kanban#attachFile" data-task-id="${task.id}" title="Anexar arquivo" style="background:none;border:1.5px solid #8b5cf6;color:#8b5cf6;border-radius:4px;cursor:pointer;font-size:0.85rem;padding:0.1rem 0.3rem">&#128206;</button>
        <button class="btn-complete" data-action="kanban#completeTask" data-task-id="${task.id}">&#10003;</button>
        <button class="btn-delete" data-action="kanban#deleteTask" data-task-id="${task.id}">&#10005;</button>
      </div>
    </div>`
  }

  columnHtml(col) {
    return `<div class="kanban-column" style="border-top-color: ${col.color}" data-column-id="${col.id}">
      <h3>${this.escapeHtml(col.name)} (<span class="task-count">0</span>)
        <button class="column-settings-btn" data-action="kanban#openEditColumn" title="Configurar">&#9881;</button>
      </h3>
      <div class="kanban-tasks" data-column-id="${col.id}"></div>
      <div class="inline-task-form">
        <input type="text" placeholder="+ Adicionar tarefa" data-action="click->kanban#expandInlineForm keydown->kanban#inlineCreateOnEnter" style="width:100%;border:none;padding:8px 10px;font-size:0.85rem;background:transparent">
      </div>
    </div>`
  }

  escapeHtml(str) {
    const d = document.createElement("div")
    d.textContent = str
    return d.innerHTML
  }

  addTagOnEnter(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.addTag(event)
    }
  }

  inlineCreateOnEnter(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.inlineCreateTask(event)
    }
  }
}
