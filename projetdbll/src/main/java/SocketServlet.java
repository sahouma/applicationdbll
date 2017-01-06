
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import org.apache.catalina.websocket.MessageInbound;
import org.apache.catalina.websocket.StreamInbound;
import org.apache.catalina.websocket.WebSocketServlet;
import org.apache.catalina.websocket.WsOutbound;
 
@WebServlet(urlPatterns = {"/SocketServlet"})
public class SocketServlet extends WebSocketServlet {
    private static final long serialVersionUID = 1L;
    private static int counter;
    private static ArrayList<SocketServlet.Connection> connections = new ArrayList<SocketServlet.Connection>();
    private static HashMap<Integer, Integer> map = new HashMap<Integer, Integer>();

    @Override
    protected StreamInbound createWebSocketInbound(String string, HttpServletRequest hsr) {
        return new SocketServlet.Connection();
    }
 
    private class Connection extends MessageInbound {
        WsOutbound wsOutbound;
        String username;
        int id;
        int targetId;
        
        @Override
        public void onOpen(WsOutbound outbound) {
            this.wsOutbound = outbound;
            connections.add(this);
            this.targetId = -1;
            this.id = counter++;
            if (this.id > 0) {
                for (Connection connection: connections) {
                    if (connection.id != this.id) {
                        if (connection.targetId == -1) {
                            connection.targetId = this.id;
                            this.targetId = connection.id;
                        }
                    }
                }
            }
        }
 
        @Override
        public void onClose(int status) {
            System.out.println(this.id + " (" + this.username + ") is leaving :(");
            if (this.targetId > -1) {
                for (Connection connection: connections) {
                    if (connection.id == this.targetId) {
                        try {
                            connection.wsOutbound.writeTextMessage(CharBuffer.wrap("leave"));
                            connection.wsOutbound.flush();
                        } catch (Exception e) { }
                        connection.targetId = -1;
                    }
                    System.out.println("Connection with id " + connection.id + " with target " + connection.targetId);
                }
            }
            connections.remove(this);
        }
 
        @Override
        public void onTextMessage(CharBuffer message) throws IOException {
            if (this.username == null) {
                this.username = message.toString();
                
                String greet = "Welcome " + message;
                System.out.println(greet);
                this.wsOutbound.writeTextMessage(CharBuffer.wrap(greet));
                
                String mark = "mark " + (connections.size() % 2 == 0 ? "o|x" : "x|o");
                System.out.println(mark);
                this.wsOutbound.writeTextMessage(CharBuffer.wrap(mark));
                
                if (connections.size() > 1) {
                    System.out.println(connections);
                    for (Connection connection : connections) {
                        System.out.println("---" + this.username + " | " + connection.username);
                        if (connection.targetId == this.id) {
                            this.wsOutbound.writeTextMessage(CharBuffer.wrap("user-target " + connection.username));
                            this.wsOutbound.flush();
                            connection.wsOutbound.writeTextMessage(CharBuffer.wrap("user-target " + this.username));
                            connection.wsOutbound.flush();
                            return;
                        }
                        System.out.println("connection " + connection.id + " target " + connection.targetId);
                    }
                }
                return;
            }
            
            if (message.toString().contains("move")) {
                Integer moveIndex = Integer.parseInt(message.toString().replace("move ", ""));
                System.out.println("move " + moveIndex);
                
                for (Connection connection : connections) {
                    if (connection.targetId == this.id) {
                        connection.wsOutbound.writeTextMessage(CharBuffer.wrap("move " + moveIndex));
                        connection.wsOutbound.flush();
                        return;
                    }
                }
                return;
            }
            
            if (message.toString().contains("gameover")) {
                for (Connection connection : connections) {
                    if (connection.targetId == this.id) {
                        this.wsOutbound.writeTextMessage(CharBuffer.wrap("gameover win"));
                        this.wsOutbound.flush();
                        connection.wsOutbound.writeTextMessage(CharBuffer.wrap("gameover lose"));
                        connection.wsOutbound.flush();
                        return;
                    }
                }
                return;
            }
        }
 
        @Override
        public void onBinaryMessage(ByteBuffer bb) throws IOException {
            
        }
    }
}