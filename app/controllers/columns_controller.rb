# frozen_string_literal: true

class ColumnsController < ApplicationController
  def update
    @column = Column.find(params[:id])
    if @column.update(column_params)
      redirect_to root_path, notice: "Coluna atualizada"
    else
      redirect_to root_path, alert: @column.errors.full_messages.to_sentence
    end
  end

  private

  def column_params
    params.require(:column).permit(:name, :color)
  end
end
