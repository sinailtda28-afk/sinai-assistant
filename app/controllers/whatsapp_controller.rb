class WhatsappController < ApplicationController
  WPP_SERVER = "http://localhost:8080"

  def send_message
    instance = params[:instance] || "default"
    number = params[:number].to_s.gsub(/\D/, "")
    message = params[:message].to_s.strip
    file_ids = params[:file_ids].to_s.split(",").map(&:strip).reject(&:blank?)

    return render json: { error: "Numero ou mensagem vazios" }, status: 422 if number.blank? || message.blank?

    file_data = nil
    file_name = nil
    file_mime = nil

    if file_ids.any?
      blob = ActiveStorage::Blob.find_by(id: file_ids.first)
      if blob
        file_data = Base64.strict_encode64(blob.download)
        file_name = blob.filename.to_s
        file_mime = blob.content_type
      end
    end

    begin
      uri = URI("#{WPP_SERVER}/send")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 20
      req = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
      body = { instance: instance, number: number, message: message }
      if file_data
        body[:file] = { data: file_data, name: file_name, mimetype: file_mime }
      end
      req.body = body.to_json
      res = http.request(req)
      data = JSON.parse(res.body)

      if data["needsReconnect"]
        render json: { success: false, error: "WhatsApp desconectado. Escaneie o QR code novamente no botao WhatsApp da barra superior.", needsQr: true }, status: 503
      elsif res.code.to_i >= 200 && res.code.to_i < 300
        render json: data
      else
        render json: { error: data["error"] || "Erro ao enviar mensagem" }, status: res.code.to_i
      end
    rescue Errno::ECONNREFUSED
      render json: { error: "Servidor WhatsApp nao encontrado. Execute: node wpp-server.js" }, status: 500
    rescue Net::ReadTimeout
      render json: { error: "Tempo limite ao enviar. Tente novamente." }, status: 504
    rescue => e
      render json: { error: e.message }, status: 500
    end
  end

  def instances
    begin
      uri = URI("#{WPP_SERVER}/instances")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 10
      res = http.get(uri.path)
      data = JSON.parse(res.body)
      render json: data
    rescue => e
      render json: [{ name: "default", connected: false }]
    end
  end

  def qrcode
    begin
      uri = URI("#{WPP_SERVER}/qrcode")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 10
      res = http.get(uri.path)
      render json: JSON.parse(res.body)
    rescue => e
      render json: { error: e.message }, status: 500
    end
  end

  def reconnect
    begin
      uri = URI("#{WPP_SERVER}/reconnect")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 15
      req = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
      res = http.request(req)
      render json: JSON.parse(res.body)
    rescue => e
      render json: { error: e.message }, status: 500
    end
  end

  def generate_message
    task = Task.find(params[:task_id])
    context = params[:context].to_s
    number = params[:number].to_s.gsub(/\D/, "")

    prompt = "Voce e um assistente pessoal. "
    if context.present?
      prompt += "Contexto adicional: #{context}. "
    end
    prompt += "Gere uma mensagem de WhatsApp curta e profissional em portugues brasileiro sobre a tarefa \"#{task.title}\""
    prompt += " (prazo: #{task.due_date.strftime('%d/%m/%Y')})" if task.due_date
    prompt += ". Inclua o valor e dados de pagamento se relevante. Apenas a mensagem, sem explicacoes."

    begin
      chat = RubyLLM.chat(model: "deepseek-chat")
      response = chat.ask(prompt)
      render json: { message: response.content.strip, number: number }
    rescue => e
      render json: { error: e.message }, status: 500
    end
  end
end
