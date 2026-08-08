// Basic API wrapper

const getAuthHeaders = () => {
  const token = localStorage.getItem('token');
  if (token) {
    return {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };
  }
  return {
    'Content-Type': 'application/json'
  };
};

export async function fetchDashboard() {
  const res = await fetch('/api/v1/admin/dashboard', {
    headers: getAuthHeaders()
  });
  if (!res.ok) {
    throw new Error('Failed to fetch dashboard data');
  }
  return res.json();
}

export async function fetchReports(page = 1, limit = 20, status = null, category = null) {
  const params = new URLSearchParams();
  params.append('page', page);
  params.append('limit', limit);
  if (status && status !== 'All') {
    params.append('status', status.toLowerCase());
  }
  if (category) {
    params.append('category', category);
  }

  const res = await fetch(`/api/v1/admin/reports?${params.toString()}`, {
    headers: getAuthHeaders()
  });
  if (!res.ok) {
    throw new Error('Failed to fetch reports');
  }
  return res.json();
}

export async function updateReportStatus(reportId, decision) {
  const res = await fetch(`/api/v1/admin/reports/${reportId}`, {
    method: 'PATCH',
    headers: getAuthHeaders(),
    body: JSON.stringify(decision)
  });
  if (!res.ok) {
    throw new Error('Failed to update report');
  }
  return res.json();
}
