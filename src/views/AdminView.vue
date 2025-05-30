<template>
  <div class="admin-container">
    <!-- Header -->
    <header class="header">
      <h1 class="title">🔧 Painel Administrativo</h1>
      <p class="subtitle">Gerenciar dados das empresas</p>
    </header>

    <!-- Auth Section -->
    <section v-if="!isAuthenticated" class="auth-section">
      <div class="auth-card">
        <h2>🔐 Autenticação</h2>
        <form @submit.prevent="authenticate" class="auth-form">
          <div class="input-group">
            <label>Senha do Administrador:</label>
            <input 
              type="password" 
              v-model="password" 
              placeholder="Digite a senha..."
              class="input-field"
              required
            >
          </div>
          <button type="submit" class="btn-primary">Entrar</button>
        </form>
        <p v-if="authError" class="error">{{ authError }}</p>
      </div>
    </section>

    <!-- Admin Panel -->
    <main v-else class="admin-panel">
      <!-- Tabs -->
      <div class="tabs">
        <button 
          v-for="tab in tabs" 
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="['tab', { active: activeTab === tab.id }]"
        >
          {{ tab.icon }} {{ tab.name }}
        </button>
      </div>

      <!-- Current Data Overview -->
      <div class="data-overview">
        <div class="stat-card">
          <span class="stat-number">{{ totalEmpresas }}</span>
          <span class="stat-label">Empresas Cadastradas</span>
        </div>
        <button @click="loadCurrentData" class="btn-secondary">🔄 Atualizar Dados</button>
      </div>

      <!-- Tab Content -->
      <!-- Upload JSON -->
      <div v-if="activeTab === 'upload'" class="tab-content">
        <h3>📤 Substituir Todos os Dados</h3>
        <div class="upload-section">
          <div class="input-group">
            <label>Cole o JSON completo:</label>
            <textarea 
              v-model="jsonInput" 
              placeholder='[{"empresa": "Google", "site": "https://google.com"}, {"empresa": "Microsoft", "site": "https://microsoft.com"}]'
              class="json-textarea"
            ></textarea>
          </div>
          <div class="button-group">
            <button @click="validateJSON" class="btn-secondary">✅ Validar JSON</button>
            <button @click="replaceAllData" class="btn-danger" :disabled="!jsonValid">🔄 Substituir Todos</button>
          </div>
          <p v-if="jsonError" class="error">{{ jsonError }}</p>
          <p v-if="jsonValid && jsonInput" class="success">✅ JSON válido - {{ parsedJSON.length }} empresas encontradas</p>
        </div>
      </div>

      <!-- Add Multiple -->
      <div v-if="activeTab === 'add'" class="tab-content">
        <h3>➕ Adicionar Múltiplas Empresas</h3>
        <div class="input-group">
          <label>JSON das empresas para adicionar:</label>
          <textarea 
            v-model="addMultipleInput" 
            placeholder='[{"empresa": "Nova Empresa", "site": "https://exemplo.com"}]'
            class="json-textarea"
          ></textarea>
        </div>
        <button @click="addMultipleData" class="btn-primary">➕ Adicionar Empresas</button>
      </div>

      <!-- Manage Data -->
      <div v-if="activeTab === 'manage'" class="tab-content">
        <h3>✏️ Gerenciar Dados Existentes</h3>
        
        <div v-if="currentData.length === 0" class="empty-state">
          <p>Nenhuma empresa cadastrada</p>
        </div>
        
        <div v-else class="manage-list">
          <div v-for="(empresa, index) in currentData" :key="index" class="manage-item">
            <div v-if="editingIndex !== index" class="item-display">
              <div class="item-info">
                <strong>{{ empresa.empresa }}</strong>
                <span class="item-url">{{ empresa.site }}</span>
              </div>
              <div class="item-actions">
                <button @click="startEdit(index)" class="btn-edit">✏️</button>
                <button @click="deleteItem(index)" class="btn-delete">🗑️</button>
              </div>
            </div>
            
            <div v-else class="item-edit">
              <div class="edit-form">
                <input 
                  v-model="editData.empresa" 
                  placeholder="Nome da empresa"
                  class="input-field"
                >
                <input 
                  v-model="editData.site" 
                  placeholder="Site da empresa"
                  class="input-field"
                >
              </div>
              <div class="edit-actions">
                <button @click="saveEdit(index)" class="btn-success">💾</button>
                <button @click="cancelEdit" class="btn-secondary">❌</button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Clear All -->
      <div v-if="activeTab === 'clear'" class="tab-content">
        <h3>🗑️ Limpar Todos os Dados</h3>
        <div class="danger-zone">
          <p>⚠️ <strong>ATENÇÃO:</strong> Esta ação irá remover TODAS as empresas cadastradas e não pode ser desfeita!</p>
          <div v-if="!showClearConfirm">
            <button @click="showClearConfirm = true" class="btn-danger">🗑️ Limpar Todos os Dados</button>
          </div>
          <div v-else class="confirm-section">
            <p>Tem certeza que deseja continuar?</p>
            <div class="button-group">
              <button @click="clearAllData" class="btn-danger">✅ Sim, Limpar Tudo</button>
              <button @click="showClearConfirm = false" class="btn-secondary">❌ Cancelar</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Messages -->
      <div v-if="message" :class="['message', messageType]">
        {{ message }}
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import axios from 'axios'

const BASE_URL = "http://localhost:3000"

// Authentication
const isAuthenticated = ref(false)
const password = ref('')
const authError = ref('')

// Tab management
const activeTab = ref('upload')
const tabs = [
  { id: 'upload', name: 'Substituir JSON', icon: '📤' },
  { id: 'add', name: 'Adicionar Múltiplas', icon: '➕' },
  { id: 'manage', name: 'Gerenciar', icon: '✏️' },
  { id: 'clear', name: 'Limpar Tudo', icon: '🗑️' }
]

// Data management
const currentData = ref<any[]>([])
const jsonInput = ref('')
const addMultipleInput = ref('')
const jsonValid = ref(false)
const jsonError = ref('')
const parsedJSON = ref<any[]>([])

// Edit functionality
const editingIndex = ref(-1)
const editData = ref({ empresa: '', site: '' })

// Clear confirmation
const showClearConfirm = ref(false)

// Messages
const message = ref('')
const messageType = ref('')

// Computed
const totalEmpresas = computed(() => currentData.value.length)

// Authentication
async function authenticate() {
  authError.value = ''
  try {
    // Test authentication with a simple request
    await axios.post(`${BASE_URL}/admin/password`, {
      password: password.value,
    })
    
    isAuthenticated.value = true
    authError.value = '' // Limpa qualquer erro de autenticação anterior
    await loadCurrentData()
  } catch (error: any) {
    // Se a requisição falhou (provavelmente 401 do checkAdminAuth), a senha está incorreta
    if (error.response && error.response.data && error.response.data.error) {
      authError.value = error.response.data.error; // Ex: "Senha incorreta"
    } else {
      authError.value = 'Erro na autenticação'; // Mensagem genérica
    }
    isAuthenticated.value = false // Garante que o estado de autenticação seja falso
  }
}

// Load current data
async function loadCurrentData() {
  try {
    const response = await axios.get(`${BASE_URL}/dados`)
    currentData.value = response.data
  } catch (error) {
    showMessage('Erro ao carregar dados', 'error')
  }
}

// Validate JSON
function validateJSON() {
  jsonError.value = ''
  jsonValid.value = false
  
  if (!jsonInput.value.trim()) {
    jsonError.value = 'JSON não pode estar vazio'
    return
  }
  
  try {
    const parsed = JSON.parse(jsonInput.value)
    if (!Array.isArray(parsed)) {
      jsonError.value = 'JSON deve ser um array'
      return
    }
    
    for (let i = 0; i < parsed.length; i++) {
      const item = parsed[i]
      if (!item.empresa || !item.site) {
        jsonError.value = `Item ${i + 1} deve ter 'empresa' e 'site'`
        return
      }
    }
    
    parsedJSON.value = parsed
    jsonValid.value = true
  } catch (error) {
    jsonError.value = 'JSON inválido'
  }
}

// Replace all data
async function replaceAllData() {
  if (!jsonValid.value) return
  
  try {
    await axios.post(`${BASE_URL}/admin/replace-all`, {
      password: password.value,
      data: parsedJSON.value
    })
    
    await loadCurrentData()
    showMessage(`Dados substituídos com sucesso! ${parsedJSON.value.length} empresas carregadas.`, 'success')
    jsonInput.value = ''
    jsonValid.value = false
  } catch (error) {
    showMessage('Erro ao substituir dados', 'error')
  }
}

// Add multiple data
async function addMultipleData() {
  try {
    const parsed = JSON.parse(addMultipleInput.value)
    if (!Array.isArray(parsed)) {
      showMessage('JSON deve ser um array', 'error')
      return
    }
    
    await axios.post(`${BASE_URL}/admin/add-multiple`, {
      password: password.value,
      data: parsed
    })
    
    await loadCurrentData()
    showMessage(`${parsed.length} empresas adicionadas com sucesso!`, 'success')
    addMultipleInput.value = ''
  } catch (error) {
    showMessage('Erro ao adicionar dados ou JSON inválido', 'error')
  }
}

// Edit functions
function startEdit(index: number) {
  editingIndex.value = index
  editData.value = { ...currentData.value[index] }
}

function cancelEdit() {
  editingIndex.value = -1
  editData.value = { empresa: '', site: '' }
}

async function saveEdit(index: number) {
  try {
    await axios.put(`${BASE_URL}/admin/edit/${index}`, {
      password: password.value,
      updatedItem: editData.value
    })
    
    await loadCurrentData()
    cancelEdit()
    showMessage('Empresa editada com sucesso!', 'success')
  } catch (error) {
    showMessage('Erro ao editar empresa', 'error')
  }
}

async function deleteItem(index: number) {
  if (!confirm('Tem certeza que deseja excluir esta empresa?')) return
  
  try {
    await axios.delete(`${BASE_URL}/admin/delete/${index}`, {
      data: { password: password.value }
    })
    
    await loadCurrentData()
    showMessage('Empresa removida com sucesso!', 'success')
  } catch (error) {
    showMessage('Erro ao remover empresa', 'error')
  }
}

// Clear all data
async function clearAllData() {
  try {
    await axios.post(`${BASE_URL}/admin/clear-all`, {
      password: password.value
    })
    
    await loadCurrentData()
    showClearConfirm.value = false
    showMessage('Todos os dados foram removidos!', 'success')
  } catch (error) {
    showMessage('Erro ao limpar dados', 'error')
  }
}

// Show message
function showMessage(msg: string, type: string) {
  message.value = msg
  messageType.value = type
  setTimeout(() => {
    message.value = ''
    messageType.value = ''
  }, 5000)
}

onMounted(() => {
  // Load current data for display even without auth
  loadCurrentData()
})
</script>

<style>
/* 1. Resetar margins e paddings padrão do body/html */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
}

/* 2. Ajustar o container principal */
.admin-container {
  min-height: 100vh;
  width: 100vw; /* Usar toda a largura da viewport */
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  padding: 20px; /* Manter padding interno, mas pode reduzir se necessário */
  margin: 0; /* Remover qualquer margin */
}

.header {
  text-align: center;
  color: white;
  margin-bottom: 2rem;
}

.title {
  font-size: 2.5rem;
  margin: 0 0 0.5rem 0;
  font-weight: 700;
}

.subtitle {
  font-size: 1.1rem;
  margin: 0;
  opacity: 0.9;
}

/* Auth Section */
.auth-section {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 60vh;
}

.auth-card {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.2);
  width: 100%;
  max-width: 400px;
}

.auth-card h2 {
  text-align: center;
  margin-bottom: 1.5rem;
  color: #333;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* Admin Panel */
.admin-panel {
  max-width: 1000px;
  margin: 0 auto;
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 10px 30px rgba(0,0,0,0.2);
}

/* Tabs */
.tabs {
  display: flex;
  background: #f8f9fa;
  border-bottom: 1px solid #dee2e6;
}

.tab {
  flex: 1;
  padding: 1rem;
  border: none;
  background: none;
  cursor: pointer;
  font-size: 0.9rem;
  color: #666;
  transition: all 0.3s;
  border-bottom: 3px solid transparent;
}

.tab:hover {
  background: #e9ecef;
}

.tab.active {
  background: white;
  color: #333;
  border-bottom-color: #007bff;
  font-weight: 600;
}

/* Data Overview */
.data-overview {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  background: #f8f9fa;
  border-bottom: 1px solid #dee2e6;
}

.stat-card {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.stat-number {
  font-size: 2rem;
  font-weight: bold;
  color: #007bff;
}

.stat-label {
  font-size: 0.9rem;
  color: #666;
}

/* Tab Content */
.tab-content {
  padding: 2rem;
}

.tab-content h3 {
  margin: 0 0 1.5rem 0;
  color: #333;
  font-size: 1.3rem;
}

/* Form Elements */
.input-group {
  margin-bottom: 1rem;
}

.input-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #333;
}

.input-field {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #dee2e6;
  border-radius: 6px;
  font-size: 1rem;
  transition: border-color 0.3s;
}

.input-field:focus {
  outline: none;
  border-color: #007bff;
}

.json-textarea {
  width: 100%;
  height: 200px;
  padding: 1rem;
  border: 2px solid #dee2e6;
  border-radius: 6px;
  font-family: 'Courier New', monospace;
  font-size: 0.9rem;
  resize: vertical;
}

.json-textarea:focus {
  outline: none;
  border-color: #007bff;
}

/* Buttons */
.btn-primary {
  background: #007bff;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 500;
  transition: all 0.3s;
}

.btn-primary:hover {
  background: #0056b3;
  transform: translateY(-1px);
}

.btn-secondary {
  background: #6c757d;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.3s;
}

.btn-secondary:hover {
  background: #545b62;
}

.btn-danger {
  background: #dc3545;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.3s;
}

.btn-danger:hover {
  background: #c82333;
}

.btn-danger:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.btn-success {
  background: #28a745;
  color: white;
  border: none;
  padding: 0.5rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
}

.btn-edit {
  background: #ffc107;
  color: #212529;
  border: none;
  padding: 0.4rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
}

.btn-delete {
  background: #dc3545;
  color: white;
  border: none;
  padding: 0.4rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8rem;
}

.button-group {
  display: flex;
  gap: 1rem;
  margin-top: 1rem;
}

/* Manage List */
.manage-list {
  max-height: 400px;
  overflow-y: auto;
}

.manage-item {
  border: 1px solid #dee2e6;
  border-radius: 6px;
  margin-bottom: 0.5rem;
  padding: 1rem;
}

.item-display, .item-edit {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.item-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.item-url {
  font-size: 0.9rem;
  color: #666;
  word-break: break-all;
}

.item-actions, .edit-actions {
  display: flex;
  gap: 0.5rem;
}

.edit-form {
  flex: 1;
  display: flex;
  gap: 1rem;
}

.edit-form .input-field {
  margin-bottom: 0;
}

/* Messages */
.message {
  position: fixed;
  top: 20px;
  right: 20px;
  padding: 1rem;
  border-radius: 6px;
  color: #212529;
  font-weight: 500;
  z-index: 1000;
  max-width: 300px;
}

.message.success {
  background: #28a745;
}

.message.error {
  background: #dc3545;
}

.error {
  color: #dc3545;
  margin-top: 0.5rem;
  font-size: 0.9rem;
}

.success {
  color: #28a745;
  margin-top: 0.5rem;
  font-size: 0.9rem;
}

.message.success {
    color: #212529;
}

/* Danger Zone */
.danger-zone {
  border: 2px solid #dc3545;
  border-radius: 8px;
  padding: 1.5rem;
  background: #fff5f5;
}

.danger-zone p {
  margin-bottom: 1rem;
  color: #721c24;
}

.confirm-section p {
  font-weight: bold;
  margin-bottom: 1rem;
}

.empty-state {
  text-align: center;
  padding: 2rem;
  color: #666;
}

/* Responsive */
@media (max-width: 768px) {
  .admin-container {
    padding: 10px;
  }
  
  .tabs {
    flex-wrap: wrap;
  }
  
  .tab {
    flex: 1 1 50%;
    font-size: 0.8rem;
    padding: 0.75rem;
  }
  
  .data-overview {
    flex-direction: column;
    gap: 1rem;
  }
  
  .button-group {
    flex-direction: column;
  }
  
  .item-display, .item-edit {
    flex-direction: column;
    align-items: stretch;
  }
  
  .edit-form {
    flex-direction: column;
  }
}
</style>