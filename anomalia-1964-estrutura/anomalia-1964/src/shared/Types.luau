--!strict

export type NomeRemoto =
    | "SolicitarInteracao"
    | "SolicitarConversa"
    | "AlertaAtualizado"
    | "InventarioAtualizado"
    | "DialogoAtualizado"
    | "SolicitarReinicio"
    | "VitoriaAtualizada"

export type NomeZona = "Recepção" | "Arquivo" | "Subsolo" | "Gabinete"

export type EstadoAlerta = "Calmo" | "Suspeito" | "Perseguindo"

export type Inventario = {
    Chaves: { string },
    Pistas: { string },
}

return {}
