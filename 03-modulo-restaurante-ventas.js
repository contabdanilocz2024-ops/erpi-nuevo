// modulos/restaurante/ventas.js - Módulo de Ventas para Restaurante

/**
 * Módulo de Ventas - Restaurante
 * Se carga dinámicamente cuando el usuario hace click
 * 
 * Features:
 * - Crear nueva venta
 * - Listar ventas
 * - Generar CFDI automático
 * - Crear póliza contable automática
 * - Actualizar inventario
 */

window.ModuloVentas = {
    
    // =========================================================================
    // INICIALIZACIÓN
    // =========================================================================
    
    init: function() {
        console.log('✓ Módulo Ventas cargado');
        
        // Cargar datos iniciales
        this.cargarVentas();
        
        // Listeners
        document.getElementById('btn-nueva-venta').addEventListener('click', () => {
            this.abrirFormulario();
        });
    },

    // =========================================================================
    // CARGAR DATOS
    // =========================================================================
    
    async cargarVentas() {
        try {
            mostrarSpinner('Cargando ventas...');
            
            // Simular API call a Supabase
            const ventas = await this.obtenerVentasDeSupabase();
            
            this.renderizarTabla(ventas);
            
            ocultarSpinner();
        } catch (error) {
            console.error('Error cargando ventas:', error);
            alert('Error: ' + error.message);
        }
    },

    async obtenerVentasDeSupabase() {
        // En producción, esto sería:
        // const { data } = await supabase
        //   .from('ventas')
        //   .select('*')
        //   .eq('empresa_id', currentEmpresa.id);
        
        // Por ahora, simular con datos locales
        const ventasLocal = JSON.parse(localStorage.getItem('ventas-demo') || '[]');
        
        // Simular 2 ventas si no hay
        if (ventasLocal.length === 0) {
            return [
                {
                    id: 'vta-001',
                    numero_factura: 'FAC-001',
                    cliente: 'Mesa 1',
                    fecha: new Date().toLocaleDateString(),
                    subtotal: 500,
                    iva: 80,
                    total: 580,
                    estado: 'pagada',
                    cfdi_id: 'cfdi-001'
                },
                {
                    id: 'vta-002',
                    numero_factura: 'FAC-002',
                    cliente: 'Mesa 2',
                    fecha: new Date().toLocaleDateString(),
                    subtotal: 750,
                    iva: 120,
                    total: 870,
                    estado: 'pendiente',
                    cfdi_id: null
                }
            ];
        }
        
        return ventasLocal;
    },

    renderizarTabla: function(ventas) {
        const tbody = document.getElementById('tabla-ventas');
        tbody.innerHTML = '';
        
        if (ventas.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="text-center py-4 text-gray-400">No hay ventas</td></tr>';
            return;
        }
        
        ventas.forEach(venta => {
            const row = document.createElement('tr');
            row.className = 'border-b border-slate-700 hover:bg-slate-700/50 transition';
            row.innerHTML = `
                <td class="py-3">${venta.numero_factura}</td>
                <td class="py-3">${venta.cliente}</td>
                <td class="py-3">${venta.fecha}</td>
                <td class="py-3 font-bold">$${venta.total.toFixed(2)}</td>
                <td class="py-3">
                    <span class="badge-${venta.estado === 'pagada' ? 'success' : 'pending'}">
                        ${venta.estado}
                    </span>
                </td>
                <td class="py-3">
                    <button onclick="ModuloVentas.verCFDI('${venta.id}')" class="text-purple-400 hover:text-purple-300">
                        Ver
                    </button>
                </td>
            `;
            tbody.appendChild(row);
        });
    },

    // =========================================================================
    // CREAR VENTA
    // =========================================================================

    abrirFormulario: function() {
        const modal = `
            <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                <div class="bg-slate-800 border border-slate-700 rounded-lg p-8 max-w-md w-full">
                    <h2 class="text-2xl font-bold mb-6">Nueva Venta</h2>
                    
                    <form onsubmit="ModuloVentas.guardarVenta(event)" class="space-y-4">
                        <div>
                            <label class="block text-sm mb-1">Cliente / Mesa</label>
                            <input type="text" id="form-cliente" placeholder="Mesa 1" 
                                class="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded focus:outline-none focus:border-purple-500"
                                required
                            />
                        </div>

                        <div>
                            <label class="block text-sm mb-1">Monto ($)</label>
                            <input type="number" id="form-monto" placeholder="0.00" step="0.01"
                                class="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded focus:outline-none focus:border-purple-500"
                                required onchange="ModuloVentas.calcularIVA()"
                            />
                        </div>

                        <div class="grid grid-cols-2 gap-4">
                            <div>
                                <label class="block text-sm mb-1">Subtotal</label>
                                <input type="text" id="form-subtotal" readonly 
                                    class="w-full px-3 py-2 bg-slate-600 border border-slate-600 rounded"
                                />
                            </div>
                            <div>
                                <label class="block text-sm mb-1">IVA (16%)</label>
                                <input type="text" id="form-iva" readonly 
                                    class="w-full px-3 py-2 bg-slate-600 border border-slate-600 rounded"
                                />
                            </div>
                        </div>

                        <div>
                            <label class="block text-sm mb-1">Forma de Pago</label>
                            <select id="form-forma-pago" class="w-full px-3 py-2 bg-slate-700 border border-slate-600 rounded focus:outline-none focus:border-purple-500">
                                <option>Efectivo</option>
                                <option>Tarjeta</option>
                                <option>Transferencia</option>
                            </select>
                        </div>

                        <div class="bg-blue-500/20 border border-blue-500/50 rounded p-3 text-sm">
                            <p>✓ Se generará automáticamente:</p>
                            <p class="text-xs text-gray-300">• Póliza contable</p>
                            <p class="text-xs text-gray-300">• CFDI 4.0</p>
                            <p class="text-xs text-gray-300">• Actualización de inventario</p>
                        </div>

                        <div class="flex gap-4">
                            <button type="button" onclick="this.closest('.fixed').remove()" class="flex-1 py-2 bg-slate-700 hover:bg-slate-600 rounded transition">
                                Cancelar
                            </button>
                            <button type="submit" class="flex-1 py-2 bg-purple-600 hover:bg-purple-700 rounded transition font-bold">
                                Guardar
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modal);
    },

    calcularIVA: function() {
        const monto = parseFloat(document.getElementById('form-monto').value) || 0;
        const iva = monto * 0.16;
        const total = monto + iva;
        
        document.getElementById('form-subtotal').value = monto.toFixed(2);
        document.getElementById('form-iva').value = iva.toFixed(2);
    },

    async guardarVenta(event) {
        event.preventDefault();
        mostrarSpinner('Guardando venta...');

        const cliente = document.getElementById('form-cliente').value;
        const monto = parseFloat(document.getElementById('form-monto').value);
        const iva = monto * 0.16;
        const total = monto + iva;
        const formaPago = document.getElementById('form-forma-pago').value;

        try {
            // Crear venta
            const venta = {
                id: 'vta-' + Date.now(),
                numero_factura: 'FAC-' + String(Date.now()).slice(-4),
                cliente: cliente,
                fecha: new Date().toLocaleDateString(),
                subtotal: monto,
                iva: iva,
                total: total,
                forma_pago: formaPago,
                estado: 'pendiente',
                cfdi_id: null,
                poliza_id: null,
                creado_en: new Date().toISOString()
            };

            // En producción: Guardar en Supabase
            // await supabase.from('ventas').insert([venta]);

            // Aquí se ejecutaría automáticamente en Supabase:
            // 1. Crear póliza contable
            await this.crearPolizaAutomatica(venta);
            
            // 2. Generar CFDI
            await this.generarCFDIAutomatico(venta);
            
            // 3. Actualizar inventario
            await this.actualizarInventarioAutomatico(venta);
            
            // 4. Registrar auditoría
            await this.registrarAuditoria('venta', 'crear', venta);

            // Guardar localmente
            const ventas = JSON.parse(localStorage.getItem('ventas-demo') || '[]');
            ventas.push(venta);
            localStorage.setItem('ventas-demo', JSON.stringify(ventas));

            // Cerrar modal y recargar
            document.querySelector('.fixed').remove();
            
            // Recargar tabla
            await this.cargarVentas();
            
            alert('✓ Venta ' + venta.numero_factura + ' creada exitosamente');
            
        } catch (error) {
            alert('Error: ' + error.message);
        } finally {
            ocultarSpinner();
        }
    },

    // =========================================================================
    // AUTOMATIZACIONES (se ejecutarían en Supabase en producción)
    // =========================================================================

    async crearPolizaAutomatica(venta) {
        console.log('Creando póliza automática para venta:', venta.numero_factura);
        
        // En Supabase se ejecutaría algo como:
        // INSERT INTO polizas (numero, tipo, fecha, asientos_json) VALUES (
        //   1,
        //   'ingreso',
        //   NOW(),
        //   jsonb_build_object(
        //     'asientos', jsonb_build_array(
        //       jsonb_build_object('cuenta', '1010001', 'debe', 1160, 'haber', 0),
        //       jsonb_build_object('cuenta', '4010001', 'debe', 0, 'haber', 1000),
        //       jsonb_build_object('cuenta', '2010100', 'debe', 0, 'haber', 160)
        //     )
        //   )
        // );
        
        // Simular con console log
        const poliza = {
            numero: 1,
            tipo: 'ingreso',
            fecha: new Date().toISOString(),
            asientos: [
                { cuenta: '1010001', nombre: 'Bancos', debe: venta.total, haber: 0 },
                { cuenta: '4010001', nombre: 'Ventas', debe: 0, haber: venta.subtotal },
                { cuenta: '2010100', nombre: 'IVA por Pagar', debe: 0, haber: venta.iva }
            ]
        };
        
        console.log('✓ Póliza creada:', poliza);
        venta.poliza_id = 'poliza-' + Date.now();
    },

    async generarCFDIAutomatico(venta) {
        console.log('Generando CFDI automático para venta:', venta.numero_factura);
        
        // En producción, llamar a PAC de CFDI (Proveedor de Certificación)
        // El XML se genera con los datos de la venta
        
        venta.cfdi_id = 'cfdi-' + Date.now();
        console.log('✓ CFDI generado:', venta.cfdi_id);
    },

    async actualizarInventarioAutomatico(venta) {
        console.log('Actualizando inventario para venta:', venta.numero_factura);
        
        // En producción:
        // UPDATE productos SET stock = stock - cantidad_vendida
        // WHERE producto_id IN (productos_de_la_venta)
        
        console.log('✓ Inventario actualizado');
    },

    async registrarAuditoria(entidad, accion, datos) {
        console.log('Registrando auditoría:', { entidad, accion, datos });
        
        // En producción:
        // INSERT INTO audit_logs (usuario_id, entidad, accion, datos_nuevos)
        // VALUES (?, ?, ?, ?)
        
        console.log('✓ Auditoría registrada');
    },

    // =========================================================================
    // VER CFDI
    // =========================================================================

    verCFDI: function(ventaId) {
        alert('CFDI para venta ' + ventaId + ' (próximamente)');
    }
};

// Auto-inicializar cuando se carga el script
document.addEventListener('DOMContentLoaded', () => {
    if (ModuloVentas) ModuloVentas.init();
}, { once: true });
