# frozen_string_literal: true

class TasksController < ApplicationController
  def index
    @columns = Column.ordered.includes(tasks: :tags)
    @tasks = Task.parent_tasks.pending

    # Apply filters
    @tasks = @tasks.by_priority_filter(params[:priority])
    @tasks = @tasks.by_tag(params[:tag])
    @tasks = @tasks.due_in_range(params[:start_date], params[:end_date])

    @filtered = params[:priority].present? || params[:tag].present? ||
                params[:start_date].present? || params[:end_date].present?

    @tags = Tag.all.order(:name)
  end

  def create
    result = Tasks::CreateTask.call(task_params)

    if result.success?
      redirect_to root_path, notice: "Tarefa criada com sucesso"
    else
      redirect_to root_path, alert: result.errors.join(", ")
    end
  end

  def update
    result = Tasks::UpdateTask.call(params[:id], task_params)

    if result.success?
      redirect_to root_path, notice: "Tarefa atualizada"
    else
      redirect_to root_path, alert: result.errors.join(", ")
    end
  end

  def destroy
    Task.find(params[:id]).destroy!
    redirect_to root_path, notice: "Tarefa excluída"
  end

  def move
    result = Tasks::MoveTask.call(params[:id], params[:to_column_id], params[:position])
    head (result.success? ? :ok : :unprocessable_entity)
  end

  private

  def task_params
    params.require(:task).permit(:title, :description, :due_date, :priority, :column_id,
                                  :parent_task_id, :is_recurring, :recurring_interval, tags: [])
  end
end
