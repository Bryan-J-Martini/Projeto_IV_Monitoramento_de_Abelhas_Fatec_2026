const canvas = document.getElementById('roiCanvas');
const ctx = canvas.getContext('2d');
const img = document.getElementById('videoStream');

let nativePolygons = [];   // Polígonos salvos em coordenadas NATIVAS da imagem
let currentPolygon = [];   // Polígono atual em construção (em coordenadas NATIVAS)

// Calcula a escala real e o offset considerando o object-contain da imagem
function getImageRenderInfo() {
    const elemW = img.clientWidth;
    const elemH = img.clientHeight;
    const natW = img.naturalWidth || elemW;
    const natH = img.naturalHeight || elemH;

    const scale = Math.min(elemW / natW, elemH / natH);
    const renderW = natW * scale;
    const renderH = natH * scale;
    const offsetX = (elemW - renderW) / 2;
    const offsetY = (elemH - renderH) / 2;

    return { elemW, elemH, natW, natH, scale, renderW, renderH, offsetX, offsetY };
}

// Sincroniza as dimensões do Canvas com o elemento de imagem visível
function syncCanvasDimensions() {
    if (img.clientWidth > 0 && img.clientHeight > 0) {
        if (canvas.width !== img.clientWidth || canvas.height !== img.clientHeight) {
            canvas.width = img.clientWidth;
            canvas.height = img.clientHeight;
            canvas.style.width = img.clientWidth + 'px';
            canvas.style.height = img.clientHeight + 'px';
        }
        draw();
    }
}

img.addEventListener('load', syncCanvasDimensions);
window.addEventListener('resize', syncCanvasDimensions);

// Define os polígonos vindos do servidor (coordenadas nativas)
window.setPolygons = function(polygonsFromBackend) {
    nativePolygons = polygonsFromBackend || [];
    syncCanvasDimensions();
};

// Retorna os polígonos em coordenadas nativas para salvar no backend
window.getPolygons = function() {
    return nativePolygons;
};

// Clique com botão esquerdo: Adiciona ponto convertido para o espaço nativo
canvas.addEventListener('click', (e) => {
    const rect = canvas.getBoundingClientRect();
    const clickX = e.clientX - rect.left;
    const clickY = e.clientY - rect.top;

    const info = getImageRenderInfo();

    // Converte de pixels da tela para pixels reais da imagem original
    const nativeX = Math.round((clickX - info.offsetX) / info.scale);
    const nativeY = Math.round((clickY - info.offsetY) / info.scale);

    // Garante que o clique ocorreu dentro da área útil da imagem
    if (nativeX >= 0 && nativeX <= info.natW && nativeY >= 0 && nativeY <= info.natH) {
        currentPolygon.push([nativeX, nativeY]);
        draw();
    }
});

// Clique com botão direito: Fecha o polígono atual
canvas.addEventListener('contextmenu', (e) => {
    e.preventDefault();
    if (currentPolygon.length > 2) {
        nativePolygons.push([...currentPolygon]);
        currentPolygon = [];
        draw();
    }
});

// Botão Limpar ROI
document.getElementById('btn-clear-roi').addEventListener('click', () => {
    nativePolygons = [];
    currentPolygon = [];
    draw();
});

// Função principal de desenho convertendo coordenadas nativas para a tela
function draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    const info = getImageRenderInfo();

    // Helper para converter coordenada nativa para o pixel atual do Canvas
    function nativeToCanvas(pt) {
        return {
            x: info.offsetX + (pt[0] * info.scale),
            y: info.offsetY + (pt[1] * info.scale)
        };
    }

    // 1. Desenha polígonos salvos (Vermelho)
    ctx.strokeStyle = '#ef4444';
    ctx.fillStyle = 'rgba(239, 68, 68, 0.25)';
    ctx.lineWidth = 2;

    nativePolygons.forEach(poly => {
        if (!poly || poly.length < 2) return;
        ctx.beginPath();
        const p0 = nativeToCanvas(poly[0]);
        ctx.moveTo(p0.x, p0.y);
        
        for (let i = 1; i < poly.length; i++) {
            const pi = nativeToCanvas(poly[i]);
            ctx.lineTo(pi.x, pi.y);
        }
        ctx.closePath();
        ctx.fill();
        ctx.stroke();

        poly.forEach(pt => {
            const cp = nativeToCanvas(pt);
            ctx.fillStyle = '#ef4444';
            ctx.beginPath();
            ctx.arc(cp.x, cp.y, 4, 0, 2 * Math.PI);
            ctx.fill();
        });
    });

    // 2. Desenha o polígono em construção (Azul)
    if (currentPolygon.length > 0) {
        ctx.strokeStyle = '#3b82f6';
        ctx.fillStyle = 'rgba(59, 130, 246, 0.25)';
        ctx.lineWidth = 2;

        ctx.beginPath();
        const p0 = nativeToCanvas(currentPolygon[0]);
        ctx.moveTo(p0.x, p0.y);

        currentPolygon.forEach(pt => {
            const cp = nativeToCanvas(pt);
            ctx.lineTo(cp.x, cp.y);
        });
        ctx.stroke();

        currentPolygon.forEach(pt => {
            const cp = nativeToCanvas(pt);
            ctx.fillStyle = '#3b82f6';
            ctx.beginPath();
            ctx.arc(cp.x, cp.y, 4, 0, 2 * Math.PI);
            ctx.fill();
        });
    }
}