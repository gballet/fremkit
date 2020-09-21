module DevP2P
  abstract class Message
    abstract def payload : Bytes
  end
end
