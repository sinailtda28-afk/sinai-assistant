class TasksController < ApplicationController
  def index
    @columns = Column.ordered.includes(tasks: :tags)
    @tasks = Task.parent_tasks.pending

    @tasks = @tasks.by_priority_filter(params[:priority])
    @tasks = @tasks.by_tag(params[:tag])
    @tasks = @tasks.due_in_range(params[:start_date], params[:end_date])

    @tags = Tag.all.order(:name)
  end

  def show
    task = Task.includes(:tags, :comments).find(params[:id])
    render json: task_json(task)
  end

  def create
    result = Tasks::CreateTask.call(task_params)

    respond_to do |format|
      format.html do
        if result.success?
          redirect_to root_path, notice: "Tarefa criada"
        else
          redirect_to root_path, alert: result.errors.join(", ")
        end
      end
      format.json do
        if result.success?
          task = Task.includes(:tags).find(result.data.id)

          inline_comment = params.dig(:task, :inline_comment) || request.headers["X-Inline-Comment"]
          if inline_comment.present?
            task.comments.create!(content: inline_comment.strip)
            task.reload
          end

          render json: task_json(task)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    result = Tasks::UpdateTask.call(params[:id], task_params)

    respond_to do |format|
      format.html do
        if result.success?
          redirect_to root_path, notice: "Tarefa atualizada"
        else
          redirect_to root_path, alert: result.errors.join(", ")
        end
      end
      format.json do
        if result.success?
          task = Task.includes(:tags).find(result.data.id)
          render json: task_json(task)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    task = Task.find(params[:id])
    task.destroy!

    respond_to do |format|
      format.html { redirect_to root_path, notice: "Tarefa excluida" }
      format.json { head :ok }
    end
  end

  def move
    result = Tasks::MoveTask.call(params[:id], params[:to_column_id], params[:position])
    head (result.success? ? :ok : :unprocessable_entity)
  end

  private

  def task_params
    params.require(:task).permit(:title, :description, :due_date, :priority, :column_id,
                                  :parent_task_id, :is_recurring, :recurring_interval,
                                  :completed_at, :link, tags: [], files: [])
  end

  def task_json(task)
    {
      id: task.id,
      title: task.title,
      description: task.description,
      due_date: task.due_date&.strftime("%d/%m/%Y"),
      created_at: task.created_at&.strftime("%d/%m/%Y"),
      priority: task.priority,
      priority_label: { "low" => "Baixa", "medium" => "Media", "high" => "Alta" }[task.priority],
      column_id: task.column_id,
      column_color: task.column.color,
      link: task.link,
      tags: task.tags.map { |t| { id: t.id, name: t.name } },
      is_recurring: task.is_recurring?,
      recurring_interval: task.recurring_interval,
      completed_at: task.completed_at&.iso8601,
      files: task.files.map { |f| { name: f.filename.to_s, url: url_for(f), id: f.id } },
      comments: task.comments.order(:created_at).map { |c| { id: c.id, content: c.content, created_at: c.created_at.strftime("%d/%m %H:%M") } }
    }
  end
end
