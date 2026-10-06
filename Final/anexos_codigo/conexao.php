<?php
/**
 * conexao.php
 * ---------------------------------------------------------------
 * Responsável APENAS por abrir a conexão com o MySQL.
 * Os outros arquivos fazem "require" deste para reaproveitar a conexão.
 *
 * Usamos PDO (PHP Data Objects) porque:
 *  - permite "prepared statements" (proteção contra SQL Injection);
 *  - lança exceções quando algo dá errado (fica fácil tratar erros).
 */

// Dados de acesso ao banco. AJUSTE conforme o MySQL que você usa:
//  - MySQL do XAMPP: usuário "root" e senha vazia ('').
//  - MySQL instalado junto com o Workbench (MySQL 8): use a senha do root
//    definida na instalação.
$host    = 'localhost';
$porta   = 3306;
$banco   = 'projeto_ferramentas';
$usuario = 'root';
$senha   = '123456';

try {
    // Monta a "string de conexão" (DSN) e cria o objeto PDO
    $pdo = new PDO(
        "mysql:host=$host;port=$porta;dbname=$banco;charset=utf8mb4",
        $usuario,
        $senha,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION, // erros viram exceções
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,       // resultados como array associativo
        ]
    );
} catch (PDOException $e) {
    // Se não conseguir conectar, devolve erro 500 em JSON e para o script
    http_response_code(500);
    echo json_encode(['erro' => 'Falha ao conectar no banco de dados']);
    exit;
}
