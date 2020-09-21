module DevP2P
  abstract class Message
    abstract def payload : Bytes
  end

  module Messages
    class Hello < Message
      def payload : Bytes
      end
    end

    class Disconnect < Message
      enum Reason
        DisconnectRequested
        TCPSubSystemError
        BreachOfProtocol
        UselessPeer
        TooManyPeers
        AlreadyConnected
        IncompatibleP2PProtocolVersion
        NullNodeIdentity
        ClientQuit
        UnexpectedIdentityInHandshake
        ConnectedToSelf
        PingTimeout
        Other
      end

      @reason : Reason = Reason::Other

      def payload : Bytes
        self.to_rlp
      end
    end

    class Ping < Message
      def payload : Bytes
        self.to_rlp
      end
    end

    class Pong < Message
      def payload : Bytes
        self.to_rlp
      end
    end
  end
end
