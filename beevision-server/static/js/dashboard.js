const HIVE_ID = "colmeia_jatai_01";
let isReceivingData = true;
let isInvertedDirection = false;

// Atualiza a aparência do botão com base no estado real do servidor
function updateButtonState(active) {
    const btn = document.getElementById('btn-toggle-stream');
    const statusIndicator = document.getElementById('connection-status');
    
    isReceivingData = active;

    if (active) {
        btn.innerText = "Pausar Recebimento";
        btn.className = "px-3 py-1 bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-semibold rounded transition shadow";
        statusIndicator.innerText = "● Sistema Operacional";
        statusIndicator.className = "text-sm bg-emerald-900/50 text-emerald-400 px-3 py-1 rounded-full border border-emerald-700/50";
    } else {
        btn.innerText = "Retomar Recebimento";
        btn.className = "px-3 py-1 bg-amber-600 hover:bg-amber-500 text-white text-xs font-semibold rounded transition shadow";
        statusIndicator.innerText = "● Pausado";
        statusIndicator.className = "text-sm bg-amber-900/50 text-amber-400 px-3 py-1 rounded-full border border-amber-700/50";
    }
}

// Atualiza o texto do indicador visual de direção na interface
function updateDirectionUI(inverted) {
    isInvertedDirection = inverted;
    const indicator = document.getElementById('direction-indicator');
    if (inverted) {
        indicator.innerText = "⟵ Sentido Invertido (Esq ➔ Dir = Entrada)";
        indicator.className = "text-xs text-amber-400 font-mono";
    } else {
        indicator.innerText = "⟶ Sentido Padrão (Dir ➔ Esq = Entrada)";
        indicator.className = "text-xs text-emerald-400 font-mono";
    }
}

// Consulta o estado do processamento no backend
async function checkProcessingStatus() {
    try {
        const response = await fetch(`/api/v1/hives/${HIVE_ID}/processing/status`);
        const result = await response.json();
        updateButtonState(result.processing_active);
    } catch (err) {
        console.error("Erro ao verificar status de processamento:", err);
    }
}

// Carrega a configuração de lógica e direção do servidor
async function loadLogicConfig() {
    try {
        const response = await fetch(`/api/v1/hives/${HIVE_ID}/config/logic`);
        const result = await response.json();
        
        document.getElementById('strategySelect').value = result.counting_strategy;
        document.getElementById('marginRange').value = result.boundary_margin_px;
        document.getElementById('marginVal').innerText = result.boundary_margin_px;
        
        updateDirectionUI(result.invert_direction);
    } catch (err) {
        console.error("Erro ao carregar configurações de lógica:", err);
    }
}

// Carrega as ROIs salvas do servidor
async function loadSavedROI() {
    try {
        const response = await fetch(`/api/v1/hives/${HIVE_ID}/roi`);
        const result = await response.json();
        
        if (result.roi_polygons && window.setPolygons) {
            window.setPolygons(result.roi_polygons);
        }
    } catch (err) {
        console.error("Erro ao carregar ROI do servidor:", err);
    }
}

// Atualiza imagem e métricas periódicas
async function fetchMetrics() {
    try {
        const response = await fetch(`/api/v1/hives/${HIVE_ID}/traffic/latest`);
        const result = await response.json();
        
        document.getElementById('metric-entries').innerText = result.data.entries;
        document.getElementById('metric-exits').innerText = result.data.exits;
        document.getElementById('metric-rate').innerText = `${result.data.traffic_rate_per_minute} / min`;
        
        const timestamp = new Date().getTime();
        document.getElementById('videoStream').src = `${result.media.annotated_frame_url}?t=${timestamp}`;
    } catch (err) {
        console.error("Erro ao buscar métricas:", err);
    }
}

// Botão de alternar pausa/retomada de dados
document.getElementById('btn-toggle-stream').addEventListener('click', async () => {
    const nextState = !isReceivingData;
    
    try {
        await fetch(`/api/v1/hives/${HIVE_ID}/processing/toggle`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ active: nextState })
        });

        updateButtonState(nextState);
    } catch (err) {
        console.error("Erro ao alterar estado de recebimento:", err);
    }
});

// Botão para alternar e SALVAR a direção instantaneamente no servidor
document.getElementById('btn-toggle-direction').addEventListener('click', async () => {
    const newInvertState = !isInvertedDirection;
    updateDirectionUI(newInvertState);

    const strategy = document.getElementById('strategySelect').value;
    const margin = parseInt(document.getElementById('marginRange').value);
    
    try {
        await fetch(`/api/v1/hives/${HIVE_ID}/config/logic`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                counting_strategy: strategy, 
                boundary_margin_px: margin,
                invert_direction: newInvertState 
            })
        });
        console.log("Direção invertida e aplicada com sucesso!");
    } catch (err) {
        console.error("Erro ao inverter direção no servidor:", err);
        alert("Erro ao comunicar com o servidor.");
    }
});

// Ação de Salvar ROI
document.getElementById('btn-save-roi').addEventListener('click', async () => {
    const currentPolys = window.getPolygons ? window.getPolygons() : [];
    
    try {
        const response = await fetch(`/api/v1/hives/${HIVE_ID}/roi`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ roi_polygons: currentPolys })
        });
        const resData = await response.json();
        if (resData.status === "success") {
            alert("ROI salva com sucesso no disco!");
        }
    } catch (err) {
        alert("Erro ao salvar ROI.");
    }
});

// Ação de Salvar Configurações Gerais
document.getElementById('btn-save-config').addEventListener('click', async () => {
    const strategy = document.getElementById('strategySelect').value;
    const margin = parseInt(document.getElementById('marginRange').value);
    
    try {
        await fetch(`/api/v1/hives/${HIVE_ID}/config/logic`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                counting_strategy: strategy, 
                boundary_margin_px: margin,
                invert_direction: isInvertedDirection 
            })
        });
        alert("Configurações atualizadas com sucesso!");
    } catch (err) {
        alert("Erro ao atualizar configurações.");
    }
});

document.getElementById('marginRange').addEventListener('input', (e) => {
    document.getElementById('marginVal').innerText = e.target.value;
});

// Inicialização da Aplicação
async function init() {
    await checkProcessingStatus();
    await loadSavedROI();
    await loadLogicConfig();
    setInterval(fetchMetrics, 1500);
    fetchMetrics();
}

init();