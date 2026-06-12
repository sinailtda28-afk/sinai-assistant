class ColumnsController < ApplicationController
  def create
    @column = Column.new(column_params)
    @column.position = Column.maximum(:position).to_i + 1

    if @column.save
      respond_to do |format|
        format.html { redirect_to root_path, notice: "Coluna criada" }
        format.json { render json: { id: @column.id, name: @column.name, color: @column.color } }
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, alert: @column.errors.full_messages.to_sentence }
        format.json { render json: { errors: @column.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    @column = Column.find(params[:id])
    if @column.update(column_params)
      respond_to do |format|
        format.html { redirect_to root_path, notice: "Coluna atualizada" }
        format.json { render json: { id: @column.id, name: @column.name, color: @column.color } }
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, alert: @column.errors.full_messages.to_sentence }
        format.json { render json: { errors: @column.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @column = Column.find(params[:id])
    @column.destroy
    respond_to do |format|
      format.html { redirect_to root_path, notice: "Coluna excluida" }
      format.json { head :ok }
    end
  end

  private

  def column_params
    params.require(:column).permit(:name, :color)
  end
end
