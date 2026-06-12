class CommentsController < ApplicationController
  def create
    task = Task.find(params[:task_id])
    comment = task.comments.create!(content: params[:content])
    render json: { id: comment.id, content: comment.content, created_at: comment.created_at.strftime("%d/%m %H:%M") }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
