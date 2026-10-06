<?php
/**
 * ferramentas.php
 * ---------------------------------------------------------------
 * Endpoint da API: http://localhost/projeto_ferramentas/ferramentas.php
 *
 *  GET  ?id=1 -> consulta uma ferramenta     (SQL: SELECT)
 *  POST       -> cadastra uma NOVA ferramenta (SQL: INSERT)
 *  PUT  ?id=1 -> altera uma ferramenta EXISTENTE (SQL: UPDATE)
 *
 * O app Flutter (ou o Postman) envia os dados no CORPO da requisição,
 * em formato JSON. Ex.: {"nome":"Furadeira","patrimonio":"FER-001"}
 */

// ------------------------------------------------------------------
// 1) CABEÇALHOS HTTP
// ------------------------------------------------------------------
header('Content-Type: application/json; charset=utf-8'); // resposta sempre em JSON
header('Access-Control-Allow-Origin: *');                 // CORS: libera chamadas de outras origens (Flutter Web)
header('Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Navegadores mandam um "OPTIONS" antes do POST/PUT (pre-flight do CORS).
// Só respondemos OK e encerramos.
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require __DIR__ . '/conexao.php'; // traz a variável $pdo

// Função auxiliar: envia a resposta em JSON com o código HTTP e encerra
function responder(int $codigo, array $corpo): void
{
    http_response_code($codigo);
    echo json_encode($corpo, JSON_UNESCAPED_UNICODE);
    exit;
}

// Lista de status permitidos (igual ao ENUM do banco)
$statusValidos = ['disponivel', 'emprestada', 'em_manutencao'];

$metodo = $_SERVER['REQUEST_METHOD'];

// ------------------------------------------------------------------
// 2) LENDO O JSON QUE CHEGOU (php://input) — só POST e PUT têm corpo
// ------------------------------------------------------------------
// $_POST só funciona com formulários (form-data) e nem existe no PUT.
// Quando o corpo é JSON, lemos o "fluxo bruto" da requisição: php://input.
$dados = [];
if ($metodo === 'POST' || $metodo === 'PUT') {
    $corpoBruto = file_get_contents('php://input');

    // json_decode transforma o texto JSON em array PHP (o "true" = array associativo)
    $dados = json_decode($corpoBruto, true);

    // Se o JSON veio vazio ou mal formatado, devolvemos 400 (Bad Request)
    if (!is_array($dados)) {
        responder(400, ['erro' => 'JSON inválido ou ausente no corpo da requisição']);
    }
}

// ------------------------------------------------------------------
// 3) DECIDINDO O QUE FAZER DE ACORDO COM O MÉTODO HTTP
// ------------------------------------------------------------------
try {
    switch ($metodo) {

        // ==========================================================
        // GET  ->  SELECT  (conferir o registro depois do POST/PUT)
        // ==========================================================
        case 'GET':
            if (isset($_GET['id'])) {
                $busca = $pdo->prepare('SELECT * FROM ferramentas WHERE id = :id');
                $busca->execute([':id' => (int) $_GET['id']]);
                $ferramenta = $busca->fetch();
                if (!$ferramenta) {
                    responder(404, ['erro' => 'Ferramenta ' . (int) $_GET['id'] . ' não encontrada']);
                }
                responder(200, $ferramenta);
            }
            // Sem ?id= devolve a lista completa
            responder(200, $pdo->query('SELECT * FROM ferramentas ORDER BY id')->fetchAll());

        // ==========================================================
        // POST  ->  INSERT  (criar um registro novo)
        // ==========================================================
        case 'POST':
            // Lendo as chaves do JSON. O "??" evita erro se a chave não existir.
            $nome        = trim($dados['nome'] ?? '');
            $patrimonio  = trim($dados['patrimonio'] ?? '');
            $status      = $dados['status'] ?? 'disponivel';
            $localizacao = $dados['localizacao'] ?? null;

            // Validação dos campos obrigatórios (422 = dados não processáveis)
            if ($nome === '' || $patrimonio === '') {
                responder(422, ['erro' => 'Os campos "nome" e "patrimonio" são obrigatórios']);
            }
            if (!in_array($status, $statusValidos, true)) {
                responder(422, ['erro' => 'Status inválido', 'permitidos' => $statusValidos]);
            }

            // Prepared statement: os ":campos" são preenchidos com segurança pelo PDO
            $sql  = 'INSERT INTO ferramentas (nome, patrimonio, status, localizacao)
                     VALUES (:nome, :patrimonio, :status, :localizacao)';
            $stmt = $pdo->prepare($sql);
            $stmt->execute([
                ':nome'        => $nome,
                ':patrimonio'  => $patrimonio,
                ':status'      => $status,
                ':localizacao' => $localizacao,
            ]);

            // 201 = Created. Devolvemos o ID gerado pelo AUTO_INCREMENT
            responder(201, [
                'mensagem' => 'Ferramenta cadastrada com sucesso',
                'id'       => (int) $pdo->lastInsertId(),
            ]);

        // ==========================================================
        // PUT  ->  UPDATE  (alterar um registro existente)
        // ==========================================================
        case 'PUT':
            // O ID vem na URL (?id=1), que é o padrão REST.
            // Por compatibilidade, também aceitamos {"id": 1} no JSON.
            $id = (int) ($_GET['id'] ?? $dados['id'] ?? 0);
            if ($id <= 0) {
                responder(422, ['erro' => 'Informe o id da ferramenta na URL: ?id=1']);
            }

            // "Lista branca": só estes campos podem ser alterados.
            // Isso impede que alguém tente alterar colunas que não deveria.
            $camposPermitidos = ['nome', 'patrimonio', 'status', 'localizacao'];

            $sets    = [];          // pedaços do SQL, ex: "status = :status"
            $valores = [':id' => $id];

            foreach ($camposPermitidos as $campo) {
                if (array_key_exists($campo, $dados)) {   // a chave veio no JSON?
                    $sets[]             = "$campo = :$campo";
                    $valores[":$campo"] = $dados[$campo];
                }
            }

            if (empty($sets)) {
                responder(422, ['erro' => 'Nenhum campo para atualizar foi enviado']);
            }
            if (isset($dados['status']) && !in_array($dados['status'], $statusValidos, true)) {
                responder(422, ['erro' => 'Status inválido', 'permitidos' => $statusValidos]);
            }

            // Monta: UPDATE ferramentas SET status = :status, localizacao = :localizacao WHERE id = :id
            $sql  = 'UPDATE ferramentas SET ' . implode(', ', $sets) . ' WHERE id = :id';
            $stmt = $pdo->prepare($sql);
            $stmt->execute($valores);

            // Buscamos o registro para devolver ao app (e saber se o ID existe:
            // rowCount() = 0 também acontece quando os valores já eram iguais)
            $busca = $pdo->prepare('SELECT * FROM ferramentas WHERE id = :id');
            $busca->execute([':id' => $id]);
            $ferramenta = $busca->fetch();

            if (!$ferramenta) {
                responder(404, ['erro' => "Ferramenta $id não encontrada"]); // 404 = não encontrado
            }

            responder(200, [                                                // 200 = OK
                'mensagem'   => 'Ferramenta atualizada com sucesso',
                'ferramenta' => $ferramenta,
            ]);

        // ==========================================================
        // Qualquer outro método (DELETE...) não é tratado aqui
        // ==========================================================
        default:
            responder(405, ['erro' => "Método $metodo não suportado neste endpoint"]); // 405 = método não permitido
    }

} catch (PDOException $e) {
    // Código 23000 = violação de chave única (ex.: patrimônio repetido)
    if ($e->getCode() === '23000') {
        responder(409, ['erro' => 'Já existe uma ferramenta com esse patrimônio']); // 409 = conflito
    }
    responder(500, ['erro' => 'Erro interno no servidor']);
}
