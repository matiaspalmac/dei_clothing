/* ===== Dei Clothing - App.js ===== */

const IS_BROWSER = !(window.invokeNative || window.GetParentResourceName);

const panel = document.getElementById('clothing-panel');
const storeTitle = document.getElementById('storeTitle');
const categoryTabs = document.getElementById('categoryTabs');
const componentEditor = document.getElementById('componentEditor');
const editorLabel = document.getElementById('editorLabel');
const drawableValue = document.getElementById('drawableValue');
const textureValue = document.getElementById('textureValue');
const outfitsView = document.getElementById('outfitsView');
const outfitsList = document.getElementById('outfitsList');
const outfitsEmpty = document.getElementById('outfitsEmpty');
const saveDialog = document.getElementById('saveDialog');
const saveInput = document.getElementById('saveInput');
const actionButtons = document.getElementById('actionButtons');
const priceTag = document.getElementById('priceTag');
const priceAmount = document.getElementById('priceAmount');

let categories = [];
let activeCategory = null;
let currentView = 'editor'; // 'editor' | 'outfits'
let outfits = [];
let maxOutfits = 15;
let isDragging = false;
let lastDragX = 0;
let dragOverlay = null;

/* ===== NUI Communication ===== */
function postNUI(event, data = {}) {
    if (IS_BROWSER) {
        return Promise.resolve({});
    }
    return fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).then(r => r.json()).catch(() => ({}));
}

/* ===== Message Handler ===== */
window.addEventListener('message', (e) => {
    const msg = e.data;

    switch (msg.action) {
        case 'open':
            openPanel(msg);
            break;
        case 'close':
            closePanel();
            break;
        case 'setTheme':
            applyTheme(msg.theme, msg.lightMode);
            break;
    }
});

/* ===== Theme ===== */
function applyTheme(theme, lightMode) {
    document.body.setAttribute('data-theme', theme || 'dark');
    document.body.classList.toggle('light-mode', !!lightMode);
}

/* ===== Open Panel ===== */
function openPanel(data) {
    storeTitle.textContent = data.storeLabel || 'Tienda de Ropa';
    categories = data.categories || [];
    maxOutfits = data.maxOutfits || 15;

    // Price
    if (data.isFree || !data.flatFee || data.flatFee <= 0) {
        priceTag.classList.add('hidden');
    } else {
        priceTag.classList.remove('hidden');
        priceAmount.textContent = '$' + data.flatFee.toLocaleString();
    }

    // Build tabs
    buildCategoryTabs();

    // Select first category
    if (categories.length > 0) {
        selectCategory(0);
    }

    // Show editor view
    showEditorView();

    panel.classList.remove('hidden', 'closing');

    // Create drag overlay for ped rotation
    createDragOverlay();
}

function closePanel() {
    panel.classList.add('closing');
    removeDragOverlay();
    setTimeout(() => {
        panel.classList.add('hidden');
        panel.classList.remove('closing');
    }, 250);
}

/* ===== Category Tabs ===== */
function buildCategoryTabs() {
    categoryTabs.innerHTML = '';
    categories.forEach((cat, index) => {
        const tab = document.createElement('button');
        tab.className = 'category-tab';
        tab.textContent = cat.label;
        tab.dataset.index = index;
        tab.addEventListener('click', () => selectCategory(index));
        categoryTabs.appendChild(tab);
    });
}

function selectCategory(index) {
    activeCategory = index;
    const cat = categories[index];

    // Update active tab
    document.querySelectorAll('.category-tab').forEach((tab, i) => {
        tab.classList.toggle('active', i === index);
    });

    // Update editor
    editorLabel.textContent = cat.label;
    updateSliderDisplay();

    // Camera zone
    postNUI('setCameraZone', { zone: cat.zone || 'full' });
}

function updateSliderDisplay() {
    if (activeCategory === null) return;
    const cat = categories[activeCategory];
    const drawNum = cat.currentDrawable + 1;
    const drawMax = cat.maxDrawable;
    const texNum = cat.currentTexture + 1;
    const texMax = cat.maxTexture;

    drawableValue.textContent = `${drawNum} / ${drawMax}`;
    textureValue.textContent = `${texNum} / ${Math.max(texMax, 1)}`;
}

/* ===== Drawable Navigation ===== */
function changeDrawable(direction) {
    if (activeCategory === null) return;
    const cat = categories[activeCategory];
    if (cat.maxDrawable <= 0) return;

    let newDrawable = cat.currentDrawable + direction;
    if (newDrawable >= cat.maxDrawable) newDrawable = 0;
    if (newDrawable < 0) newDrawable = cat.maxDrawable - 1;

    cat.currentDrawable = newDrawable;
    cat.currentTexture = 0;

    const event = cat.type === 'component' ? 'changeComponent' : 'changeProp';
    postNUI(event, {
        id: cat.id,
        drawable: newDrawable,
        texture: 0,
    }).then((resp) => {
        if (resp && resp.maxTexture !== undefined) {
            cat.maxTexture = resp.maxTexture;
            cat.currentTexture = resp.currentTexture || 0;
        }
        updateSliderDisplay();
    });
}

function changeTexture(direction) {
    if (activeCategory === null) return;
    const cat = categories[activeCategory];
    const maxTex = Math.max(cat.maxTexture, 1);

    let newTexture = cat.currentTexture + direction;
    if (newTexture >= maxTex) newTexture = 0;
    if (newTexture < 0) newTexture = maxTex - 1;

    cat.currentTexture = newTexture;

    const event = cat.type === 'component' ? 'changeComponent' : 'changeProp';
    postNUI(event, {
        id: cat.id,
        drawable: cat.currentDrawable,
        texture: newTexture,
    }).then(() => {
        updateSliderDisplay();
    });
}

/* ===== Button Handlers ===== */
document.getElementById('drawablePrev').addEventListener('click', () => changeDrawable(-1));
document.getElementById('drawableNext').addEventListener('click', () => changeDrawable(1));
document.getElementById('texturePrev').addEventListener('click', () => changeTexture(-1));
document.getElementById('textureNext').addEventListener('click', () => changeTexture(1));

document.getElementById('btnClose').addEventListener('click', () => {
    postNUI('closeClothing');
});

document.getElementById('btnConfirm').addEventListener('click', () => {
    postNUI('confirmPurchase');
});

document.getElementById('btnCancel').addEventListener('click', () => {
    postNUI('cancelClothing');
});

/* ===== Save Outfit ===== */
document.getElementById('btnSaveOutfit').addEventListener('click', () => {
    saveDialog.classList.remove('hidden');
    saveInput.value = '';
    saveInput.focus();
});

document.getElementById('saveCancelBtn').addEventListener('click', () => {
    saveDialog.classList.add('hidden');
});

document.getElementById('saveConfirmBtn').addEventListener('click', () => {
    const name = saveInput.value.trim();
    if (!name) return;

    postNUI('saveOutfit', { name }).then((resp) => {
        saveDialog.classList.add('hidden');
        if (resp && resp.outfits) {
            outfits = resp.outfits;
        }
    });
});

saveInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
        document.getElementById('saveConfirmBtn').click();
    } else if (e.key === 'Escape') {
        saveDialog.classList.add('hidden');
    }
});

/* ===== My Outfits ===== */
document.getElementById('btnMyOutfits').addEventListener('click', () => {
    showOutfitsView();
    postNUI('loadOutfits').then((resp) => {
        outfits = (resp && resp.outfits) || [];
        renderOutfits();
    });
});

document.getElementById('outfitsBack').addEventListener('click', () => {
    showEditorView();
});

function showOutfitsView() {
    currentView = 'outfits';
    componentEditor.classList.add('hidden');
    categoryTabs.classList.add('hidden');
    actionButtons.classList.add('hidden');
    outfitsView.classList.remove('hidden');
}

function showEditorView() {
    currentView = 'editor';
    outfitsView.classList.add('hidden');
    componentEditor.classList.remove('hidden');
    categoryTabs.classList.remove('hidden');
    actionButtons.classList.remove('hidden');
}

function renderOutfits() {
    outfitsList.innerHTML = '';

    if (outfits.length === 0) {
        outfitsEmpty.classList.remove('hidden');
        outfitsList.classList.add('hidden');
        return;
    }

    outfitsEmpty.classList.add('hidden');
    outfitsList.classList.remove('hidden');

    outfits.forEach((outfit) => {
        const item = document.createElement('div');
        item.className = 'outfit-item';

        const name = document.createElement('span');
        name.className = 'outfit-name';
        name.textContent = outfit.name;

        const actions = document.createElement('div');
        actions.className = 'outfit-actions';

        // Apply button
        const applyBtn = document.createElement('button');
        applyBtn.className = 'outfit-btn apply';
        applyBtn.title = 'Aplicar';
        applyBtn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>';
        applyBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            postNUI('loadOutfit', { outfit: outfit.data });
            showEditorView();
            // Refresh categories with loaded data
            if (outfit.data) {
                refreshCategoriesFromOutfit(outfit.data);
            }
        });

        // Delete button
        const deleteBtn = document.createElement('button');
        deleteBtn.className = 'outfit-btn delete';
        deleteBtn.title = 'Eliminar';
        deleteBtn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"></path></svg>';
        deleteBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            postNUI('deleteOutfit', { name: outfit.name }).then((resp) => {
                if (resp && resp.success) {
                    outfits = resp.outfits || [];
                    renderOutfits();
                }
            });
        });

        actions.appendChild(applyBtn);
        actions.appendChild(deleteBtn);
        item.appendChild(name);
        item.appendChild(actions);
        outfitsList.appendChild(item);
    });
}

function refreshCategoriesFromOutfit(data) {
    if (!data) return;
    categories.forEach((cat) => {
        const key = String(cat.id);
        if (cat.type === 'component' && data.components && data.components[key]) {
            cat.currentDrawable = data.components[key].drawable;
            cat.currentTexture = data.components[key].texture;
        } else if (cat.type === 'prop' && data.props && data.props[key]) {
            cat.currentDrawable = data.props[key].drawable;
            cat.currentTexture = data.props[key].texture;
        }
    });
    updateSliderDisplay();
}

/* ===== Drag to Rotate ===== */
function createDragOverlay() {
    removeDragOverlay();
    dragOverlay = document.createElement('div');
    dragOverlay.className = 'drag-overlay';
    document.body.appendChild(dragOverlay);

    dragOverlay.addEventListener('mousedown', (e) => {
        isDragging = true;
        lastDragX = e.clientX;
    });

    document.addEventListener('mousemove', onDragMove);
    document.addEventListener('mouseup', onDragEnd);
}

function removeDragOverlay() {
    if (dragOverlay) {
        dragOverlay.remove();
        dragOverlay = null;
    }
    document.removeEventListener('mousemove', onDragMove);
    document.removeEventListener('mouseup', onDragEnd);
    isDragging = false;
}

function onDragMove(e) {
    if (!isDragging) return;
    const deltaX = e.clientX - lastDragX;
    lastDragX = e.clientX;
    const rotationSpeed = 0.5;
    postNUI('rotateCamera', { delta: deltaX * rotationSpeed });
}

function onDragEnd() {
    isDragging = false;
}

/* ===== Keyboard Navigation ===== */
document.addEventListener('keydown', (e) => {
    if (panel.classList.contains('hidden')) return;
    if (currentView !== 'editor') return;
    if (document.activeElement === saveInput) return;

    switch (e.key) {
        case 'ArrowLeft':
            e.preventDefault();
            changeDrawable(-1);
            break;
        case 'ArrowRight':
            e.preventDefault();
            changeDrawable(1);
            break;
        case 'ArrowUp':
            e.preventDefault();
            changeTexture(1);
            break;
        case 'ArrowDown':
            e.preventDefault();
            changeTexture(-1);
            break;
        case 'Escape':
            e.preventDefault();
            postNUI('closeClothing');
            break;
    }
});

/* ===== IS_BROWSER Preview ===== */
if (IS_BROWSER) {
    // Add preview background
    const bg = document.createElement('div');
    bg.className = 'preview-bg';
    document.body.appendChild(bg);

    // Mock data
    openPanel({
        storeLabel: 'Tienda de Ropa - Vinewood',
        categories: [
            { type: 'component', id: 11, label: 'Chaquetas', currentDrawable: 2, maxDrawable: 45, currentTexture: 1, maxTexture: 8, zone: 'torso' },
            { type: 'component', id: 3, label: 'Camisetas', currentDrawable: 5, maxDrawable: 32, currentTexture: 0, maxTexture: 4, zone: 'torso' },
            { type: 'component', id: 8, label: 'Camiseta Interior', currentDrawable: 0, maxDrawable: 16, currentTexture: 0, maxTexture: 2, zone: 'torso' },
            { type: 'component', id: 4, label: 'Pantalones', currentDrawable: 12, maxDrawable: 58, currentTexture: 3, maxTexture: 12, zone: 'legs' },
            { type: 'component', id: 6, label: 'Zapatos', currentDrawable: 7, maxDrawable: 40, currentTexture: 0, maxTexture: 6, zone: 'feet' },
            { type: 'component', id: 1, label: 'Mascaras', currentDrawable: 0, maxDrawable: 120, currentTexture: 0, maxTexture: 3, zone: 'head' },
            { type: 'component', id: 7, label: 'Accesorios', currentDrawable: 0, maxDrawable: 28, currentTexture: 0, maxTexture: 5, zone: 'torso' },
            { type: 'component', id: 9, label: 'Chalecos', currentDrawable: 0, maxDrawable: 18, currentTexture: 0, maxTexture: 4, zone: 'torso' },
            { type: 'component', id: 5, label: 'Bolsos', currentDrawable: 0, maxDrawable: 15, currentTexture: 0, maxTexture: 2, zone: 'torso' },
            { type: 'component', id: 10, label: 'Insignias', currentDrawable: 0, maxDrawable: 10, currentTexture: 0, maxTexture: 1, zone: 'torso' },
            { type: 'prop', id: 0, label: 'Sombreros', currentDrawable: 3, maxDrawable: 85, currentTexture: 1, maxTexture: 6, zone: 'head' },
            { type: 'prop', id: 1, label: 'Gafas', currentDrawable: 1, maxDrawable: 30, currentTexture: 0, maxTexture: 4, zone: 'head' },
            { type: 'prop', id: 2, label: 'Orejas', currentDrawable: -1, maxDrawable: 12, currentTexture: 0, maxTexture: 3, zone: 'head' },
            { type: 'prop', id: 6, label: 'Relojes', currentDrawable: 0, maxDrawable: 22, currentTexture: 0, maxTexture: 5, zone: 'torso' },
            { type: 'prop', id: 7, label: 'Pulseras', currentDrawable: -1, maxDrawable: 8, currentTexture: 0, maxTexture: 2, zone: 'torso' },
        ],
        isFree: false,
        flatFee: 200,
        maxOutfits: 15,
    });

    // Mock outfits for preview
    outfits = [
        { name: 'Casual Diario', data: {} },
        { name: 'Traje Formal', data: {} },
        { name: 'Deportivo', data: {} },
    ];
}
