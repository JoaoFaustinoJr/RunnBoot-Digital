# RunnBoot Digital — contrato de multiplayer (planejamento)

Status: arquitetura documentada; **não conectado ao servidor**.

## Princípios
- Uma única peça por equipe; partidas individuais usam uma peça por jogador.
- Cada equipe possui uma ordem estável de participantes e um índice de capitão.
- Somente o capitão atual pode confirmar resposta e executar ação de turno.
- O professor organiza e pausa a arena; não precisa jogar.
- Cada sala possui um código de convite, mas código não substitui autenticação.
- O servidor valida todas as transições; clientes apenas solicitam ações.

## Entidades propostas
- `rooms`: id, invite_code, owner_user_id, status, current_team_id, turn_number, version.
- `teams`: id, room_id, name, position, score, captain_member_id.
- `members`: id, room_id, team_id, user_id, display_name, seat_order, connected_at.
- `turns`: id, room_id, team_id, captain_member_id, dice, challenge_id, phase, started_at, completed_at.
- `answers`: id, turn_id, member_id, choice, correct, awarded_points.
- `events`: id, room_id, turn_number, type, payload, created_at.

## Operações atômicas futuras
1. Criar sala e gerar código único.
2. Entrar na sala autenticando participante e atribuindo equipe.
3. Iniciar partida após professor confirmar a composição.
4. Lançar dado uma única vez por turno.
5. Registrar resposta exclusivamente do capitão; avaliar no servidor.
6. Mover peça e atualizar pontuação na mesma transação.
7. Encerrar turno e rotacionar capitão para o próximo participante elegível.
8. Reingressar após desconexão e recuperar o estado canônico.

## Segurança
- Políticas RLS em todas as tabelas expostas.
- Identidade autorizada derivada da sessão autenticada, nunca de nomes digitados.
- Nunca colocar chave service_role/secret no HTML público.
- Não confiar em pontuação, dado, acerto ou capitão enviados pelo navegador.
- Evitar compartilhar dados entre RunnBoot, Tangram X1 e RAI Connect sem isolamento rigoroso.
- Dados de menores: coletar o mínimo necessário e definir retenção e acesso docente.

## Critérios de aceitação
- Dois dispositivos na mesma sala veem o mesmo turno e a mesma posição.
- Um integrante não capitão não consegue confirmar resposta nem via requisição direta.
- Dois cliques simultâneos não duplicam jogada ou pontuação.
- Reconexão preserva a equipe e o capitão.
- Sala encerrada não aceita novas jogadas.

Próximo passo: provisionar infraestrutura adequada e implementar backend validado antes de habilitar convites remotos.
