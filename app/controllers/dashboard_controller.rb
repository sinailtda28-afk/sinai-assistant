class DashboardController < ApplicationController
  def index
    today = Date.current
    @start_of_month = today.beginning_of_month
    @last_month = today.last_month

    # Metricas do mes atual
    @created_this_month = Task.where(created_at: @start_of_month..today.end_of_day).count
    @completed_this_month = Task.completed.where(completed_at: @start_of_month..today.end_of_day).count

    # Mes anterior
    @created_last_month = Task.where(created_at: @last_month.beginning_of_month..@last_month.end_of_month.end_of_day).count
    @completed_last_month = Task.completed.where(completed_at: @last_month.beginning_of_month..@last_month.end_of_month.end_of_day).count

    # Taxa de conclusao
    @completion_rate = @created_this_month > 0 ? (@completed_this_month.to_f / @created_this_month * 100).round(1) : 0

    # Tarefas atrasadas
    @overdue_count = Task.pending.parent_tasks.overdue.count
    @total_pending = Task.pending.parent_tasks.count
    @overdue_rate = @total_pending > 0 ? (@overdue_count.to_f / @total_pending * 100).round(1) : 0

    # Distribuicao por prioridade
    @high_priority = Task.pending.parent_tasks.where(priority: "high").count
    @medium_priority = Task.pending.parent_tasks.where(priority: "medium").count
    @low_priority = Task.pending.parent_tasks.where(priority: "low").count

    # Evolucao semanal (ultimas 8 semanas)
    @weekly_data = (0..7).map do |week_offset|
      week_start = today.beginning_of_week - week_offset.weeks
      week_end = week_start.end_of_week
      {
        week: week_start.strftime("%d/%m"),
        created: Task.where(created_at: week_start..week_end).count,
        completed: Task.completed.where(completed_at: week_start..week_end).count
      }
    end.reverse

    # Dias mais produtivos
    @most_productive_days = Task.completed
      .where(completed_at: @start_of_month..today.end_of_day)
      .group("strftime('%w', completed_at)")
      .count
      .sort_by { |_, count| -count }
      .first(3)
      .map { |day_num, count| [%w[Domingo Segunda-feira Terca-feira Quarta-feira Quinta-feira Sexta-feira Sabado][day_num.to_i], count] }
  end
end
