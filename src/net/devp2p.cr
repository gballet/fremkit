module DevP2P
  abstract class Message
    abstract def payload : Bytes
  end

  module Messages
    class Hello < Message
      @protocol_version = 5u8
      @client_id : Bytes | Nil
      @caps : Array({String, UInt8}) = [{"eth", 64u8}]
      @listen_port : UInt16 = 0
      @node_id : Bytes | Nil

      def payload : Bytes
        self.to_rlp
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
