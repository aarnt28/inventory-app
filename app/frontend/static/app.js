const els = {
    status: document.querySelector('[data-status]'),
    items: document.querySelector('[data-items]'),
    transactions: document.querySelector('[data-transactions]'),
    itemForm: document.querySelector('#item-form'),
    transactionForm: document.querySelector('#transaction-form'),
    barcodeOptions: document.querySelector('#barcode-options'),
    metrics: {
        items: document.querySelector('[data-metric="items"]'),
        transactions: document.querySelector('[data-metric="transactions"]'),
    },
    refreshItems: document.querySelector('[data-refresh-items]'),
    refreshTransactions: document.querySelector('[data-refresh-transactions]'),
};

const state = {
    items: [],
    transactions: [],
};

const api = {
    items: '/api/items/',
    transactions: '/api/transactions/',
};

const escapeHtml = (value) =>
    (value || '')
        .toString()
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');

const setStatus = (message, tone = 'muted') => {
    if (!els.status) return;
    els.status.textContent = message;
    els.status.classList.remove('status--error', 'status--muted');
    if (tone === 'error') {
        els.status.classList.add('status--error');
    } else if (tone === 'muted') {
        els.status.classList.add('status--muted');
    }
};

const fetchJSON = async (url, options = {}) => {
    const response = await fetch(url, options);
    let data = null;
    try {
        data = await response.json();
    } catch (_) {
        data = null;
    }
    if (!response.ok) {
        const detail = data?.detail || response.statusText || 'Request failed';
        throw new Error(detail);
    }
    return data;
};

const updateMetrics = () => {
    if (els.metrics.items) {
        els.metrics.items.textContent = state.items.length;
    }
    if (els.metrics.transactions) {
        els.metrics.transactions.textContent = state.transactions.length;
    }
};

const renderItemOptions = () => {
    if (!els.barcodeOptions) return;
    els.barcodeOptions.innerHTML = state.items
        .map(
            (item) =>
                `<option value="${escapeHtml(item.barcode)}">${escapeHtml(
                    item.name || item.barcode
                )}</option>`
        )
        .join('');
};

const renderItems = () => {
    if (!els.items) return;
    if (!state.items.length) {
        els.items.innerHTML = '<p class="muted">No items yet. Capture your first item to populate the catalog.</p>';
        return;
    }

    const cards = state.items.map((item) => {
        const preview = item.preview_url
            ? `<img class="item-card__thumb" src="${escapeHtml(item.preview_url)}" alt="${escapeHtml(item.name)}">`
            : '<div class="item-card__thumb item-card__thumb--placeholder">No image</div>';

        const description = item.description || 'No description yet.';
        const sku = item.sku ? `<span class="badge">SKU ${escapeHtml(item.sku)}</span>` : '';

        return `
            <article class="item-card">
                ${preview}
                <div class="item-card__body">
                    <div class="item-card__meta">
                        <span class="badge badge--accent">Qty ${item.quantity ?? 0}</span>
                        ${sku}
                    </div>
                    <h4 class="item-card__title">${escapeHtml(item.name)}</h4>
                    <p class="muted">Barcode ${escapeHtml(item.barcode)}</p>
                    <p class="muted">${escapeHtml(description)}</p>
                </div>
            </article>
        `;
    });

    els.items.innerHTML = cards.join('');
};

const formatDate = (dateString) => {
    const date = new Date(dateString);
    if (Number.isNaN(date.getTime())) return '';
    return date.toLocaleString(undefined, {
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    });
};

const renderTransactions = () => {
    if (!els.transactions) return;
    if (!state.transactions.length) {
        els.transactions.innerHTML = '<p class="muted">No transactions yet.</p>';
        return;
    }

    const limited = [...state.transactions]
        .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
        .slice(0, 10);

    const rows = limited.map((tx) => {
        const typeClass = `tag--${tx.type || 'adjust'}`;
        const notes = tx.notes ? `<div class="muted">${escapeHtml(tx.notes)}</div>` : '';
        const vendor = tx.vendor_client ? ` · ${escapeHtml(tx.vendor_client)}` : '';
        const device = tx.device_id ? ` · ${escapeHtml(tx.device_id)}` : '';
        return `
            <div class="transaction">
                <div class="transaction__row">
                    <div>
                        <strong>${escapeHtml(tx.barcode)}</strong>
                        <span class="transaction__meta">${escapeHtml(tx.type)}</span>
                    </div>
                    <span class="tag ${typeClass}">${escapeHtml(tx.type)}</span>
                </div>
                <div class="transaction__row">
                    <div class="transaction__meta">Amount ${tx.amount}${vendor}${device}</div>
                    <div class="transaction__meta">${formatDate(tx.timestamp)}</div>
                </div>
                ${notes}
            </div>
        `;
    });

    els.transactions.innerHTML = rows.join('');
};

const loadItems = async () => {
    setStatus('Loading items...', 'muted');
    try {
        const data = await fetchJSON(api.items);
        state.items = data;
        renderItems();
        renderItemOptions();
        updateMetrics();
        setStatus('Items synced.', 'muted');
    } catch (err) {
        setStatus(`Failed to load items: ${err.message}`, 'error');
    }
};

const loadTransactions = async () => {
    setStatus('Loading transactions...', 'muted');
    try {
        const data = await fetchJSON(api.transactions);
        state.transactions = data;
        renderTransactions();
        updateMetrics();
        setStatus('Activity up to date.', 'muted');
    } catch (err) {
        setStatus(`Failed to load transactions: ${err.message}`, 'error');
    }
};

const handleItemSubmit = async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const formData = new FormData(form);

    if (formData.get('image_url') && formData.get('image_file') && formData.get('image_file').name) {
        setStatus('Use either an image URL or an upload, not both.', 'error');
        return;
    }

    setStatus('Saving item...', 'muted');
    try {
        await fetchJSON(api.items, {
            method: 'POST',
            body: formData,
        });
        form.reset();
        await loadItems();
        setStatus('Item saved.', 'muted');
    } catch (err) {
        setStatus(`Could not save item: ${err.message}`, 'error');
    }
};

const handleTransactionSubmit = async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const data = new FormData(form);

    const payload = {
        barcode: (data.get('barcode') || '').trim(),
        amount: Number(data.get('amount')),
        type: data.get('type') || 'add',
        unit_cost: data.get('unit_cost') ? Number(data.get('unit_cost')) : null,
        device_id: data.get('device_id') || null,
        vendor_client: data.get('vendor_client') || null,
        notes: data.get('notes') || null,
        trans_source: 'frontend',
    };

    if (!payload.barcode) {
        setStatus('Barcode is required.', 'error');
        return;
    }

    setStatus('Logging transaction...', 'muted');
    try {
        await fetchJSON(api.transactions, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(payload),
        });
        form.reset();
        form.querySelector('#type').value = 'add';
        form.querySelector('#amount').value = 1;
        await loadTransactions();
        setStatus('Transaction logged.', 'muted');
    } catch (err) {
        setStatus(`Could not log transaction: ${err.message}`, 'error');
    }
};

const bindEvents = () => {
    els.itemForm?.addEventListener('submit', handleItemSubmit);
    els.transactionForm?.addEventListener('submit', handleTransactionSubmit);
    els.refreshItems?.addEventListener('click', loadItems);
    els.refreshTransactions?.addEventListener('click', loadTransactions);
};

const init = async () => {
    bindEvents();
    await Promise.all([loadItems(), loadTransactions()]);
    setStatus('Ready to capture inventory.', 'muted');
};

init();
