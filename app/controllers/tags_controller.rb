class TagsController < ApplicationController
  def index
    tags = Tag.all.order(:name)
    render json: tags.map { |t| { id: t.id, name: t.name } }
  end

  def create
    tag = Tag.create!(name: params[:name].strip.downcase)
    render json: { id: tag.id, name: tag.name }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    tag = Tag.find(params[:id])
    task_tags_count = tag.task_tags.count
    tag.destroy
    render json: { id: params[:id], removed_from: task_tags_count }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
