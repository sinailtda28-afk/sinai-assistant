class CreateWhatsappInstances < ActiveRecord::Migration[8.1]
  def change
    create_table :whatsapp_instances do |t|
      t.string :name
      t.string :number
      t.boolean :active

      t.timestamps
    end
  end
end
