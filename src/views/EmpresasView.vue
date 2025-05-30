<script setup lang="ts">
import axios from 'axios';
import { onMounted, ref } from 'vue';

const api = ref<any>(null);
const empresasPaginadas = ref<any[]>([]);
const paginaAtual = ref(1);
const porPagina = 10;

function atualizarPaginacao() {
  const inicio = (paginaAtual.value - 1) * porPagina;
  const fim = inicio + porPagina;
  empresasPaginadas.value = api.value.slice(inicio, fim);
}

function proximaPagina() {
  if (paginaAtual.value * porPagina < api.value.length) {
    paginaAtual.value++;
    atualizarPaginacao();
  }
}

function paginaAnterior() {
  if (paginaAtual.value > 1) {
    paginaAtual.value--;
    atualizarPaginacao();
  }
}

const novaEmpresa = ref({
  empresa: '',
  site: ''
})

const BASE_URL = "http://localhost:3000"

async function pegarEmpresas(){
  try {
     const response = await axios.get(`${BASE_URL}/dados`)
     api.value = response.data
     atualizarPaginacao();
  } catch (error) {
    console.error('Erro ao buscar API:', error)
  }
}

async function adicionarEmpresa() {
  try {
    const response = await axios.post(`${BASE_URL}/dados`, {
      empresa: novaEmpresa.value.empresa,
      site: novaEmpresa.value.site
    })
    api.value.unshift(response.data)
    novaEmpresa.value.empresa = ''
    novaEmpresa.value.site = ''
    atualizarPaginacao();
  } catch (error) {
    console.error('Erro ao criar Empresa:', error)
  }
}

onMounted(() => {
    pegarEmpresas()
})
</script>

<template>
  <div class="app-container">
    <!-- Header -->
    <header class="header">
      <h1 class="title">Gerenciamento de Empresas</h1>
      <p class="subtitle">Organize e acesse suas empresas favoritas</p>
    </header>

    <!-- Loading State -->
    <div v-if="!api" class="loading-container">
      <div class="loading-spinner"></div>
      <p class="loading-text">Carregando dados...</p>
    </div>

    <!-- Main Content -->
    <main v-else class="main-content">
      <!-- Add Company Form -->
      <section class="form-section">
        <h2 class="section-title">Adicionar Nova Empresa</h2>
        <form @submit.prevent="adicionarEmpresa" class="form">
          <div class="input-group">
            <label for="empresa" class="input-label">Nome da Empresa</label>
            <input 
              id="empresa"
              type="text" 
              placeholder="Ex: Google, Microsoft, Apple..." 
              v-model="novaEmpresa.empresa" 
              required
              class="input-field"
            >
          </div>
          <div class="input-group">
            <label for="site" class="input-label">Website</label>
            <input 
              id="site"
              type="url" 
              placeholder="https://exemplo.com" 
              v-model="novaEmpresa.site" 
              required
              class="input-field"
            >
          </div>
          <button type="submit" class="btn-primary">
            <span class="btn-text">Adicionar Empresa</span>
          </button>
        </form>
      </section>

      <!-- Companies List -->
      <section class="list-section">
        <div class="section-header">
          <h2 class="section-title">Empresas Cadastradas</h2>
          <span class="total-count">{{ api.length }} empresas no total</span>
        </div>

        <div class="companies-grid">
          <div 
            v-for="(empresa, index) in empresasPaginadas" 
            :key="index"
            class="company-card"
          >
            <div class="company-info">
              <h3 class="company-name">{{ empresa.empresa }}</h3>
              <a 
                :href="empresa.site" 
                target="_blank" 
                rel="noopener noreferrer"
                class="company-link"
              >
                {{ empresa.site }}
                <span class="external-icon">↗</span>
              </a>
            </div>
          </div>
        </div>

        <!-- Pagination -->
        <div class="pagination">
          <button 
            @click="paginaAnterior" 
            :disabled="paginaAtual === 1"
            class="btn-pagination"
            :class="{ 'btn-disabled': paginaAtual === 1 }"
          >
            ← Anterior
          </button>
          
          <div class="pagination-info">
            <span class="page-indicator">
              Página <strong>{{ paginaAtual }}</strong> de <strong>{{ Math.ceil(api.length / porPagina) }}</strong>
            </span>
          </div>
          
          <button 
            @click="proximaPagina" 
            :disabled="paginaAtual * porPagina >= api.length"
            class="btn-pagination"
            :class="{ 'btn-disabled': paginaAtual * porPagina >= api.length }"
          >
            Próxima →
          </button>
        </div>
      </section>
    </main>
  </div>
</template>

<style scoped>
* {
  box-sizing: border-box;
}

.app-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  color: #1a202c;
  padding: 0;
  margin: 0;
}

/* Header */
.header {
  background: white;
  padding: 2rem 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  text-align: center;
  margin-bottom: 2rem;
}

.title {
  font-size: 2.5rem;
  font-weight: 700;
  color: #2d3748;
  margin: 0 0 0.5rem 0;
  letter-spacing: -0.025em;
}

.subtitle {
  font-size: 1.1rem;
  color: #718096;
  margin: 0;
  font-weight: 400;
}

/* Loading */
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 50vh;
  gap: 1rem;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #e2e8f0;
  border-top: 3px solid #4299e1;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.loading-text {
  color: #718096;
  font-size: 1.1rem;
  margin: 0;
}

/* Main Content */
.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1.5rem 3rem;
}

/* Form Section */
.form-section {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
  margin-bottom: 3rem;
  border: 1px solid #e2e8f0;
}

.section-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: #2d3748;
  margin: 0 0 1.5rem 0;
}

.form {
  display: grid;
  grid-template-columns: 1fr 1fr auto;
  gap: 1.5rem;
  align-items: end;
}

.input-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.input-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: #4a5568;
  margin: 0;
}

.input-field {
  padding: 0.75rem 1rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 1rem;
  transition: all 0.2s ease;
  background: white;
  color: #2d3748;
}

.input-field:focus {
  outline: none;
  border-color: #4299e1;
  box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.1);
}

.input-field::placeholder {
  color: #a0aec0;
}

.btn-primary {
  background: linear-gradient(135deg, #4299e1 0%, #3182ce 100%);
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 2px 4px rgba(66, 153, 225, 0.2);
  height: fit-content;
}

.btn-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(66, 153, 225, 0.3);
}

.btn-primary:active {
  transform: translateY(0);
}

/* List Section */
.list-section {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
  border: 1px solid #e2e8f0;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e2e8f0;
}

.total-count {
  background: #edf2f7;
  color: #4a5568;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 500;
}

/* Companies Grid */
.companies-grid {
  display: grid;
  gap: 1rem;
  margin-bottom: 2rem;
}

.company-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1.5rem;
  transition: all 0.2s ease;
}

.company-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  border-color: #cbd5e0;
}

.company-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.company-name {
  font-size: 1.1rem;
  font-weight: 600;
  color: #2d3748;
  margin: 0;
  flex: 1;
}

.company-link {
  color: #4299e1;
  text-decoration: none;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  transition: color 0.2s ease;
  word-break: break-all;
  max-width: 300px;
}

.company-link:hover {
  color: #3182ce;
  text-decoration: underline;
}

.external-icon {
  font-size: 0.75rem;
  opacity: 0.7;
}

/* Pagination */
.pagination {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 2rem;
  border-top: 1px solid #e2e8f0;
}

.btn-pagination {
  background: white;
  color: #4a5568;
  border: 2px solid #e2e8f0;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-pagination:hover:not(.btn-disabled) {
  background: #f7fafc;
  border-color: #cbd5e0;
  transform: translateY(-1px);
}

.btn-disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.pagination-info {
  text-align: center;
}

.page-indicator {
  color: #4a5568;
  font-size: 0.9rem;
}

.page-indicator strong {
  color: #2d3748;
}

/* Responsive Design */
@media (max-width: 768px) {
  .header {
    padding: 1.5rem 1rem;
  }
  
  .title {
    font-size: 2rem;
  }
  
  .main-content {
    padding: 0 1rem 2rem;
  }
  
  .form {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
  
  .form-section,
  .list-section {
    padding: 1.5rem;
  }
  
  .section-header {
    flex-direction: column;
    gap: 1rem;
    align-items: flex-start;
  }
  
  .company-info {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  
  .company-link {
    max-width: 100%;
  }
  
  .pagination {
    flex-direction: column;
    gap: 1rem;
  }
}

@media (max-width: 480px) {
  .title {
    font-size: 1.75rem;
  }
  
  .subtitle {
    font-size: 1rem;
  }
  
  .form-section,
  .list-section {
    padding: 1rem;
  }
}
</style>