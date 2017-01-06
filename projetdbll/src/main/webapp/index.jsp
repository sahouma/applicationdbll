<%-- 
    Document   : index
    Created on : Jul 7, 2013, 6:49:21 PM
    Author     : novalagung
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>

<!DOCTYPE html>
<html>
    <head>
        <meta charset=UTF-8>
        <title>Simple Web Socket Game</title>
        <script src="//ajax.googleapis.com/ajax/libs/jquery/1.10.1/jquery.min.js"></script>
        <script>
            $(function() {
                var socket
                  , username
                  , container = $('#container')
                  , markSelf = ''
                  , markTarget = ''
                  , playerTurn;
                  
                if (document.location.host.indexOf('.com') !== -1) {
                    socket = new WebSocket("ws://tictactoe-novalagung.rhcloud.com:8000/SocketServlet")
                } else {
                    socket = new WebSocket("ws://192.168.11.184:8080/tictactoe/SocketServlet")
                }
                
                socket.onopen = function() {
                    /**if (localStorage) {
                        if (typeof localStorage['username'] !== 'undefined') {
                            username = localStorage['username'];
                            socket.send(username);
                            return;
                        }
                    }
                    localStorage['username'] = */username = prompt('Who are you ?');
                    if (username === null || typeof username === 'undefined' || !username || username === '') {
                        window.close();
                    }
                    socket.send(username);
                };
                
                socket.onmessage = function(data) {
                    var message = data.data;
                    console.log('message ' + message);
                    
                    if (markSelf === '' && message.indexOf('mark') !== -1) {
                        markSelf = message.replace('mark ', '').split('|')[0];
                        markTarget = message.replace('mark ', '').split('|')[1];
                        playerTurn = markSelf === 'o';
                        $('#name-self').html(username);
                        playerTurn = false;
                        container.css('pointer-events', 'auto');
                        return;
                    }
                    
                    if (message.indexOf('user-target') !== -1) {
                        $('#name-target').html(message.replace('user-target ', ''));
                        playerTurn = true;
                    }
                    
                    if (message.indexOf('move') !== -1) {
                        var move = message.replace('move ', '');
                        var item = $(container.find('.item')[move]);
                        item.html(markTarget);
                        calculate();
                        playerTurn = true;
                        return;
                    }
                    
                    if (message.indexOf('gameover') !== -1) {
                        if (message.indexOf('win') !== -1) {
                            alert('Game Over, You Won !');
                        } else {
                            alert('Game Over, You Lose :(');
                        }
                        if (prompt('Play again (y/n) ?') === 'y') {
                            window.location.reload();
                        }
                    }
                    
                    if (message.indexOf('leave') !== -1) {
                        alert('Your enemy leave the game :(');
                        if (prompt('Play again (y/n) ?') === 'y') {
                            window.location.reload();
                        }
                    }
                };
                
                for (i = 0; i < 9; i++) {
                    container.append($('<div/>').attr('data-id', i).addClass('item'));
                }
                
                var items = container.find('.item');
                
                container.find('.item').click(function(){
                   if ($(this).html() !== '') return;
                   if (!playerTurn) {
                       alert('Not your turn !');
                       return;
                   }
                   $(this).html(markSelf);
                   socket.send('move ' + $(this).attr('data-id'));
                   calculate();
                   playerTurn = false;
                });
                
                function val(i) {
                    var bool = $(items[i]).html() === markSelf && $(items[i]).html() !== '';
                    if (!bool) bool = Math.random();
                    return bool;
                }
                
                function calculate() {
                    var win = false;
                           if (val(0) === val(1) && val(1) === val(2)) {
                        win = true;
                    } else if (val(3) === val(4) && val(4) === val(5)) {
                        win = true;
                    } else if (val(6) === val(7) && val(7) === val(8)) {
                        win = true;
                    } else if (val(0) === val(3) && val(3) === val(6)) {
                        win = true;
                    } else if (val(1) === val(4) && val(4) === val(7)) {
                        win = true;
                    } else if (val(2) === val(5) && val(5) === val(8)) {
                        win = true;
                    } else if (val(0) === val(4) && val(4) === val(8)) {
                        win = true;
                    } else if (val(2) === val(4) && val(4) === val(6)) {
                        win = true;
                    }
                    
                    if (win) {
                        socket.send('gameover');
                    }
                }
            });
        </script>
        <style>
            #container {
                height: 300px;
                width: 300px;
                pointer-events: none;
            }
            #container > div {
                height: 100px;
                width: 100px;
                float: left;
                box-sizing: border-box;
                border: 1px solid black;
                font-size: 32px;
                padding: 25px 40px;
            }
        </style>
    </head>
    <body>
        You : <span id="name-self"></span>, vs <span id="name-target">waiting other player ...</span>
        <div id="container">
            
        </div>
    </body>
</html>