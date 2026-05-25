const express = require('express');
const cors = require('cors');
const { seed } = require('./seed');

const authRoutes = require('./routes/api/auth');
const leadsRoutes = require('./routes/api/leads');
const opportunitiesRoutes = require('./routes/api/opportunities');
const customersRoutes = require('./routes/api/customers');
const contactsRoutes = require('./routes/api/contacts');
const visitsRoutes = require('./routes/api/visits');
const contractsRoutes = require('./routes/api/contracts');
const approvalsRoutes = require('./routes/api/approvals');
const tasksRoutes = require('./routes/api/tasks');
const productsRoutes = require('./routes/api/products');
const quotesRoutes = require('./routes/api/quotes');
const reportsRoutes = require('./routes/api/reports');
const notificationsRoutes = require('./routes/api/notifications');
const teamRoutes = require('./routes/api/team');

seed();

const app = express();
const PORT = process.env.PORT || 3002;

app.use(cors({ origin: true }));
app.use(express.json());

app.get('/health', (_req, res) => res.json({ ok: true, service: 'crm-sales' }));

app.use('/api/auth', authRoutes);
app.use('/api/leads', leadsRoutes);
app.use('/api/opportunities', opportunitiesRoutes);
app.use('/api/customers', customersRoutes);
app.use('/api/contacts', contactsRoutes);
app.use('/api/visits', visitsRoutes);
app.use('/api/contracts', contractsRoutes);
app.use('/api/approvals', approvalsRoutes);
app.use('/api/tasks', tasksRoutes);
app.use('/api/products', productsRoutes);
app.use('/api/quotes', quotesRoutes);
app.use('/api/reports', reportsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/team', teamRoutes);

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`CRM backend running at http://localhost:${PORT}`);
    console.log(`API base: http://localhost:${PORT}/api`);
  });
}

module.exports = app;
