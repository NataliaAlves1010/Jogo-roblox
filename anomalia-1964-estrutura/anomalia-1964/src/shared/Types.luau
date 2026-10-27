--!strict

export type NomeRemoto =
    | "SolicitarInteracao"
    | "SolicitarConversa"
    | "AlertaAtualizado"
    | "InventarioAtualizado"
    | "DialogoAtualizado"
    | "SolicitarReinicio"
    | "VitoriaAtualizada"
    | "SolicitarSprint"
    | "PistaColetadaCliente"
    | "RuidoEmitido"
    | "TrechoRecebido"

export type NomeZona = "Recepção" | "Arquivo" | "Subsolo" | "Gabinete"

export type EstadoAlerta = "Calmo" | "Suspeito" | "Perseguindo"

export type Inventario = {
    Chaves: { string },
    Pistas: { string },
}

-- Enviado do servidor ao cliente que coletou a pista: oculta o objeto no mundo
export type PistaColetadaCliente = {
    PistaId: string,
}

-- Enviado do servidor aos módulos do guarda: posição do ruído gerado pela coleta
export type AlertaRuido = {
    Posicao: Vector3,
    Celula: Vector2,
}

-- Enviado do servidor ao cliente: trecho da carta desbloqueado
export type TrechoCarta = {
    PistaId: string,
    LetterId: string,
    Trecho: string,
}

return {}
