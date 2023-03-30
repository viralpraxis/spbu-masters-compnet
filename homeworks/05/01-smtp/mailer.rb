require "net/smtp"
require "time"
require "securerandom"

module Mailer
  SMTP_HOST = "smtp.gmail.com"
  SMTP_PORT = 25

  FROM_ADDRESS = "iaroslav2k@gmail.com"
  FROM_NAME = "Yaroslav K"

  module_function

  def invoke(to:, secret:)
    Net::SMTP.start(SMTP_HOST, SMTP_PORT, user: FROM_ADDRESS, secret: secret, authtype: :plain) do |smtp|
      smtp.send_message build_message(to: to), FROM_ADDRESS, to
    end
  end

  def build_message(to:)
    <<~END_OF_MESSAGE
    From: #{FROM_NAME} <#{FROM_ADDRESS}>
    To: Jane Dow <#{to}>
    Subject: Test message
    Date: #{Time.now.iso8601}
    Message-Id: <#{SecureRandom.hex}@gmail.com>
    Content-Type: multipart/alternative; boundary="boundary-string"

    --your-boundary
    Content-Type: text/plain; charset="utf-8"
    Content-Transfer-Encoding: quoted-printable
    Content-Disposition: inline

    Test message body

    --boundary-string
    Content-Type: text/html; charset="utf-8"
    Content-Transfer-Encoding: quoted-printable
    Content-Disposition: inline

    <p>Test message body</p>

    --boundary-string--
    END_OF_MESSAGE
  end
end

Mailer.invoke(
  to: ARGV[0] || raise(ArgumentError, "Missing to"),
  secret: ENV.fetch("GMAIL_SMTP_SECRET") || raise(ArgumentError, "Missing env variable GMAIL_SMTP_SECRET")
)

puts :OK
