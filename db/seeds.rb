# frozen_string_literal: true

columns = [
  { name: "A Fazer", position: 1, color: "#6b7280" },
  { name: "Em Andamento", position: 2, color: "#3b82f6" },
  { name: "Concluído", position: 3, color: "#10b981" }
]

columns.each do |attrs|
  Column.find_or_create_by!(name: attrs[:name]) do |col|
    col.position = attrs[:position]
    col.color = attrs[:color]
  end
end
