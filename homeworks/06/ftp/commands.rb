# frozen_string_literal: true

module Commands
    CRLF = "\r\n"

    module_function

    def getline(socket)
        line = socket.readline
        line.sub!(/(\r\n|\n|\r)\z/n, "")
        return line
    end

    def readlines(socket)
        lines = []
        lines << getline(socket)
        code = lines.last.slice(/\A([0-9a-zA-Z]{3})-/, 1)
        if code
        delimiter = code + " "
        begin
            lines << getline(socket)
        end until lines.last.start_with?(delimiter)
        end
        return lines.join("\n") + "\n"
    end

    def user(socket, username:)
        socket.write("USER #{username}#{CRLF}")
        readlines(socket)
    end

    def pass(socket, password:)
        socket.write("PASS #{password}#{CRLF}")
        readlines(socket)
    end

    def quit(socket)
        socket.write("QUIT#{CRLF}")
    end

    def pwd(socket)
        socket.write("PWD#{CRLF}")
        readlines(socket)
    end

    # NLST is a more compact version of LIST
    def ls(socket)
        socket.write("NLST#{CRLF}")
        readlines(socket)
    end

    def pasv(socket)
        socket.write("PASV#{CRLF}")
        readlines(socket)
    end

    def cwd(socket, destination:)
        socket.write("CWD #{destination}#{CRLF}")
        readlines(socket)
    end

    def retv(socket, path:)
        socket.write("RETR #{path}#{CRLF}")
        readlines(socket)
    end

    def stor(socket, path:)
        socket.write("STOR #{path}#{CRLF}")
        readlines(socket)
    end
end