(() => {
  fetch('/api/modules/tickets/overview', {credentials: 'same-origin'}).then(response => {if (!response.ok) throw new Error(); return response.json();}).then(data => {
    if (data.version !== 1 || !Array.isArray(data.metrics)) throw new Error();
    for (const metric of data.metrics) {
      if (!['total', 'active', 'resolved'].includes(metric.key)) continue;
      document.getElementById(`overview-tickets-${metric.key}`).textContent = metric.value;
      document.getElementById(`overview-tickets-${metric.key}-change`).textContent = metric.detail;
    }
  }).catch(() => {document.getElementById('overview-tickets-status').textContent = 'Ticket statistics are currently unavailable.';});
})();
