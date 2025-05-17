-- Drop existing messages table if it exists
DROP TABLE IF EXISTS mensagens;

-- Create new messages table
CREATE TABLE mensagens (
    id INT AUTO_INCREMENT PRIMARY KEY,
    chat_id INT NOT NULL,
    sender_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (chat_id) REFERENCES chat(idchat),
    FOREIGN KEY (sender_id) REFERENCES usuarios(id),
    INDEX idx_chat_messages (chat_id, created_at)
);