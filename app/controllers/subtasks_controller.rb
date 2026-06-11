class SubtasksController < ApplicationController
  def create
    Subtasks::CreateSubtask.call(params[:task_id], params[:subtask][:title])
    redirect_to root_path
  end

  def update
    subtask = Subtask.find(params[:id])
    Subtasks::CompleteSubtask.call(params[:id]) if params[:subtask][:completed] == "1"
    redirect_to root_path
  end
end
