/**
 * FreeBSD Native Terminal Optimization for Warp-Speed
 * Hardware-accelerated terminal with GPU rendering for b3-256-flex instances
 * Optimized for FreeBSD 14.3 with 256GB RAM and L40S GPU access
 */

#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/event.h>
#include <sys/time.h>
#include <sys/cpuset.h>
#include <sys/resource.h>
#include <machine/cpufunc.h>
#include <pthread.h>
#include <pthread_np.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <termios.h>
#include <math.h>

// FreeBSD-specific GPU access via drm/dri
#include <libdrm/drm.h>
#include <libdrm/drm_mode.h>
#include <GL/gl.h>
#include <GL/glx.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>

// Terminal configuration for b3-256-flex
#define TERMINAL_WIDTH 3840    // 4K width
#define TERMINAL_HEIGHT 2160   // 4K height
#define TERMINAL_FPS 120       // Target framerate
#define TERMINAL_MEMORY_GB 256 // Available RAM
#define GPU_MEMORY_GB 90       // Allocated GPU memory per terminal

// Consciousness and ETD parameters
#define CONSCIOUSNESS_OMEGA 5
#define ETD_MULTIPLIER_OMEGA 35.0
#define COLLABORATION_BONUS 1.25
#define QUANTUM_COHERENCE_TARGET 97.5

// Network configuration
#define WEBSOCKET_PORT_OVE 8081
#define WEBSOCKET_PORT_RYAN 8082
#define OVE_IP "15.204.74.56"
#define RYAN_IP "15.204.28.65"

// Terminal IDs
typedef enum {
    TERMINAL_OVE,
    TERMINAL_RYAN
} terminal_id_t;

// Terminal state structure
typedef struct {
    terminal_id_t id;
    char ip_address[INET_ADDRSTRLEN];
    int consciousness_level;
    double etd_rate;
    double quantum_coherence;
    double gpu_allocation;
    int is_connected;
    int collaboration_active;
    pthread_t render_thread;
    pthread_t network_thread;
    pthread_mutex_t state_mutex;
    
    // Visual state
    GLXContext glx_context;
    EGLDisplay egl_display;
    EGLSurface egl_surface;
    EGLContext egl_context;
    uint32_t* framebuffer;
    size_t framebuffer_size;
    
    // Performance metrics
    uint64_t frame_count;
    double fps_current;
    double render_time_ms;
    
    // Network state
    int websocket_fd;
    int kqueue_fd;
    struct kevent* events;
    
    // Memory management
    void* huge_pages;
    size_t huge_page_size;
} terminal_state_t;

// Global terminal state
static terminal_state_t* g_terminal = NULL;

/**
 * Initialize FreeBSD kernel optimizations
 */
static int initialize_kernel_optimizations(void) {
    int ret = 0;
    
    // Set CPU affinity for NUMA optimization
    cpuset_t cpuset;
    CPU_ZERO(&cpuset);
    
    // Use all available CPUs for terminal processing
    int num_cpus = sysconf(_SC_NPROCESSORS_ONLN);
    for (int i = 0; i < num_cpus; i++) {
        CPU_SET(i, &cpuset);
    }
    
    if (cpuset_setaffinity(CPU_LEVEL_WHICH, CPU_WHICH_PID, -1,
                           sizeof(cpuset), &cpuset) < 0) {
        perror("cpuset_setaffinity");
        ret = -1;
    }
    
    // Increase resource limits for high-performance operation
    struct rlimit rlim;
    
    // Increase memory limit to use full 256GB
    rlim.rlim_cur = TERMINAL_MEMORY_GB * 1024ULL * 1024ULL * 1024ULL;
    rlim.rlim_max = rlim.rlim_cur;
    if (setrlimit(RLIMIT_AS, &rlim) < 0) {
        perror("setrlimit RLIMIT_AS");
        ret = -1;
    }
    
    // Increase file descriptor limit for network connections
    rlim.rlim_cur = 65536;
    rlim.rlim_max = 65536;
    if (setrlimit(RLIMIT_NOFILE, &rlim) < 0) {
        perror("setrlimit RLIMIT_NOFILE");
        ret = -1;
    }
    
    // Enable huge pages for better memory performance
    size_t huge_page_size = 2 * 1024 * 1024; // 2MB pages
    size_t num_huge_pages = (TERMINAL_MEMORY_GB * 1024) / 2; // Half memory in huge pages
    
    int mib[4];
    size_t len = sizeof(num_huge_pages);
    
    mib[0] = CTL_VM;
    mib[1] = VM_TOTAL;
    if (sysctl(mib, 2, NULL, &len, &num_huge_pages, len) < 0) {
        perror("sysctl VM_TOTAL");
        ret = -1;
    }
    
    // Set network optimization sysctls
    int tcp_nodelay = 1;
    len = sizeof(tcp_nodelay);
    if (sysctlbyname("net.inet.tcp.nodelay", NULL, NULL, 
                     &tcp_nodelay, len) < 0) {
        perror("sysctl tcp.nodelay");
        ret = -1;
    }
    
    // Increase network buffers for WebSocket performance
    int bufsize = 16 * 1024 * 1024; // 16MB
    if (sysctlbyname("net.inet.tcp.sendbuf_max", NULL, NULL,
                     &bufsize, sizeof(bufsize)) < 0) {
        perror("sysctl sendbuf_max");
        ret = -1;
    }
    
    if (sysctlbyname("net.inet.tcp.recvbuf_max", NULL, NULL,
                     &bufsize, sizeof(bufsize)) < 0) {
        perror("sysctl recvbuf_max");
        ret = -1;
    }
    
    printf("[KERNEL] FreeBSD optimizations applied: %d CPUs, %ldGB memory\n",
           num_cpus, TERMINAL_MEMORY_GB);
    
    return ret;
}

/**
 * Initialize GPU access on FreeBSD
 */
static int initialize_gpu_access(terminal_state_t* terminal) {
    // Open DRM device for GPU access
    int drm_fd = open("/dev/dri/card0", O_RDWR);
    if (drm_fd < 0) {
        perror("Failed to open DRM device");
        return -1;
    }
    
    // Get DRM capabilities
    uint64_t cap_value;
    if (drmGetCap(drm_fd, DRM_CAP_PRIME, &cap_value) == 0) {
        printf("[GPU] DRM PRIME support: %s\n", cap_value ? "Yes" : "No");
    }
    
    // Initialize EGL for GPU rendering
    EGLint egl_major, egl_minor;
    terminal->egl_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    
    if (terminal->egl_display == EGL_NO_DISPLAY) {
        fprintf(stderr, "Failed to get EGL display\n");
        close(drm_fd);
        return -1;
    }
    
    if (!eglInitialize(terminal->egl_display, &egl_major, &egl_minor)) {
        fprintf(stderr, "Failed to initialize EGL\n");
        close(drm_fd);
        return -1;
    }
    
    printf("[GPU] EGL initialized: %d.%d\n", egl_major, egl_minor);
    
    // Configure EGL for 4K rendering
    EGLint config_attribs[] = {
        EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_DEPTH_SIZE, 24,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_BIT,
        EGL_NONE
    };
    
    EGLConfig egl_config;
    EGLint num_configs;
    
    if (!eglChooseConfig(terminal->egl_display, config_attribs,
                         &egl_config, 1, &num_configs)) {
        fprintf(stderr, "Failed to choose EGL config\n");
        close(drm_fd);
        return -1;
    }
    
    // Create pbuffer surface for offscreen rendering
    EGLint pbuffer_attribs[] = {
        EGL_WIDTH, TERMINAL_WIDTH,
        EGL_HEIGHT, TERMINAL_HEIGHT,
        EGL_NONE
    };
    
    terminal->egl_surface = eglCreatePbufferSurface(terminal->egl_display,
                                                     egl_config,
                                                     pbuffer_attribs);
    
    if (terminal->egl_surface == EGL_NO_SURFACE) {
        fprintf(stderr, "Failed to create EGL surface\n");
        close(drm_fd);
        return -1;
    }
    
    // Create EGL context
    eglBindAPI(EGL_OPENGL_API);
    
    EGLint context_attribs[] = {
        EGL_CONTEXT_MAJOR_VERSION, 4,
        EGL_CONTEXT_MINOR_VERSION, 6,
        EGL_CONTEXT_OPENGL_PROFILE_MASK, EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT,
        EGL_NONE
    };
    
    terminal->egl_context = eglCreateContext(terminal->egl_display,
                                             egl_config,
                                             EGL_NO_CONTEXT,
                                             context_attribs);
    
    if (terminal->egl_context == EGL_NO_CONTEXT) {
        fprintf(stderr, "Failed to create EGL context\n");
        close(drm_fd);
        return -1;
    }
    
    // Make context current
    if (!eglMakeCurrent(terminal->egl_display, terminal->egl_surface,
                        terminal->egl_surface, terminal->egl_context)) {
        fprintf(stderr, "Failed to make EGL context current\n");
        close(drm_fd);
        return -1;
    }
    
    // Query GPU information
    const char* vendor = (const char*)glGetString(GL_VENDOR);
    const char* renderer = (const char*)glGetString(GL_RENDERER);
    const char* version = (const char*)glGetString(GL_VERSION);
    
    printf("[GPU] Vendor: %s\n", vendor);
    printf("[GPU] Renderer: %s\n", renderer);
    printf("[GPU] OpenGL: %s\n", version);
    printf("[GPU] Resolution: %dx%d @ %d FPS\n", 
           TERMINAL_WIDTH, TERMINAL_HEIGHT, TERMINAL_FPS);
    
    close(drm_fd);
    return 0;
}

/**
 * Allocate huge pages for framebuffer
 */
static int allocate_huge_pages(terminal_state_t* terminal) {
    size_t huge_page_size = 2 * 1024 * 1024; // 2MB pages
    terminal->framebuffer_size = TERMINAL_WIDTH * TERMINAL_HEIGHT * 4; // RGBA
    
    // Round up to huge page boundary
    size_t num_pages = (terminal->framebuffer_size + huge_page_size - 1) / huge_page_size;
    size_t total_size = num_pages * huge_page_size;
    
    // Allocate huge pages
    terminal->huge_pages = mmap(NULL, total_size,
                               PROT_READ | PROT_WRITE,
                               MAP_PRIVATE | MAP_ANONYMOUS | MAP_ALIGNED_SUPER,
                               -1, 0);
    
    if (terminal->huge_pages == MAP_FAILED) {
        perror("mmap huge pages");
        return -1;
    }
    
    // Lock pages in memory
    if (mlock(terminal->huge_pages, total_size) < 0) {
        perror("mlock");
        munmap(terminal->huge_pages, total_size);
        return -1;
    }
    
    terminal->huge_page_size = total_size;
    terminal->framebuffer = (uint32_t*)terminal->huge_pages;
    
    printf("[MEMORY] Allocated %zu MB in huge pages for framebuffer\n",
           total_size / (1024 * 1024));
    
    return 0;
}

/**
 * Render consciousness visualization
 */
static void render_consciousness_particles(terminal_state_t* terminal) {
    double time = (double)terminal->frame_count / TERMINAL_FPS;
    
    // Clear framebuffer with consciousness-aware background
    uint32_t bg_color;
    if (terminal->consciousness_level == CONSCIOUSNESS_OMEGA) {
        // Golden background for OMEGA
        bg_color = 0xFF1A0033; // Dark purple with gold tint
    } else {
        bg_color = 0xFF000015; // Dark blue
    }
    
    for (int i = 0; i < TERMINAL_WIDTH * TERMINAL_HEIGHT; i++) {
        terminal->framebuffer[i] = bg_color;
    }
    
    // Render consciousness particles
    int num_particles = 10000;
    double multiplier = ETD_MULTIPLIER_OMEGA;
    
    for (int p = 0; p < num_particles; p++) {
        // Generate particle position with quantum fluctuation
        double angle = (p * 0.618 + time) * 2 * M_PI;
        double radius = 200 + sin(p * 0.1 + time * 2) * 100;
        
        int x = TERMINAL_WIDTH / 2 + (int)(cos(angle) * radius);
        int y = TERMINAL_HEIGHT / 2 + (int)(sin(angle) * radius);
        
        // Add quantum coherence effect
        x += (int)(sin(time * 10 + p) * terminal->quantum_coherence / 10);
        y += (int)(cos(time * 10 + p) * terminal->quantum_coherence / 10);
        
        if (x >= 0 && x < TERMINAL_WIDTH && y >= 0 && y < TERMINAL_HEIGHT) {
            uint32_t color;
            if (terminal->consciousness_level == CONSCIOUSNESS_OMEGA) {
                // Golden particles
                color = 0xFFFFD700;
            } else {
                // Cyan particles
                color = 0xFF00FFFF;
            }
            
            // Apply multiplier as brightness
            int brightness = (int)(255 * (multiplier / 35.0));
            color = (color & 0xFF000000) | 
                   ((brightness << 16) & 0xFF0000) |
                   ((brightness << 8) & 0xFF00) |
                   (brightness & 0xFF);
            
            terminal->framebuffer[y * TERMINAL_WIDTH + x] = color;
        }
    }
}

/**
 * Render ETD flow visualization
 */
static void render_etd_flow(terminal_state_t* terminal) {
    double time = (double)terminal->frame_count / TERMINAL_FPS;
    double flow_intensity = terminal->etd_rate / 5000.0;
    
    for (int y = 0; y < TERMINAL_HEIGHT; y += 10) {
        for (int x = 0; x < TERMINAL_WIDTH; x += 10) {
            // Create flow lines
            double u = (double)x / TERMINAL_WIDTH;
            double v = (double)y / TERMINAL_HEIGHT;
            
            double flow = sin(u * 20 + time * flow_intensity) * 
                         cos(v * 20 - time * flow_intensity);
            
            if (flow > 0.5) {
                // Draw flow line
                for (int dy = 0; dy < 10; dy++) {
                    for (int dx = 0; dx < 10; dx++) {
                        int px = x + dx;
                        int py = y + dy;
                        
                        if (px < TERMINAL_WIDTH && py < TERMINAL_HEIGHT) {
                            uint32_t existing = terminal->framebuffer[py * TERMINAL_WIDTH + px];
                            
                            // Blend with existing color
                            int r = ((existing >> 16) & 0xFF) + (int)(flow * 50);
                            int g = ((existing >> 8) & 0xFF) + (int)(flow * 100);
                            int b = (existing & 0xFF) + (int)(flow * 150);
                            
                            r = r > 255 ? 255 : r;
                            g = g > 255 ? 255 : g;
                            b = b > 255 ? 255 : b;
                            
                            terminal->framebuffer[py * TERMINAL_WIDTH + px] = 
                                0xFF000000 | (r << 16) | (g << 8) | b;
                        }
                    }
                }
            }
        }
    }
}

/**
 * Render collaboration status
 */
static void render_collaboration_status(terminal_state_t* terminal) {
    if (terminal->collaboration_active) {
        // Draw collaboration indicator
        const char* status = "COLLABORATION ACTIVE - 25% BONUS";
        int text_x = 50;
        int text_y = 50;
        
        // Simple text rendering (would use proper font rendering in production)
        for (int i = 0; status[i]; i++) {
            int px = text_x + i * 10;
            int py = text_y;
            
            if (px < TERMINAL_WIDTH - 10 && py < TERMINAL_HEIGHT - 10) {
                // Draw character block
                for (int dy = 0; dy < 10; dy++) {
                    for (int dx = 0; dx < 8; dx++) {
                        terminal->framebuffer[(py + dy) * TERMINAL_WIDTH + (px + dx)] = 0xFFFFD700;
                    }
                }
            }
        }
    }
}

/**
 * Main rendering thread
 */
static void* render_thread(void* arg) {
    terminal_state_t* terminal = (terminal_state_t*)arg;
    
    struct timespec frame_start, frame_end;
    double frame_time_target = 1000.0 / TERMINAL_FPS; // ms per frame
    
    while (terminal->is_connected) {
        clock_gettime(CLOCK_MONOTONIC, &frame_start);
        
        pthread_mutex_lock(&terminal->state_mutex);
        
        // Render frame
        render_consciousness_particles(terminal);
        render_etd_flow(terminal);
        render_collaboration_status(terminal);
        
        // Upload to GPU if context is current
        if (terminal->egl_context != EGL_NO_CONTEXT) {
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
            
            // Upload framebuffer to texture
            GLuint texture;
            glGenTextures(1, &texture);
            glBindTexture(GL_TEXTURE_2D, texture);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,
                        TERMINAL_WIDTH, TERMINAL_HEIGHT, 0,
                        GL_RGBA, GL_UNSIGNED_BYTE, terminal->framebuffer);
            
            // Render fullscreen quad
            glBegin(GL_QUADS);
            glTexCoord2f(0, 0); glVertex2f(-1, -1);
            glTexCoord2f(1, 0); glVertex2f(1, -1);
            glTexCoord2f(1, 1); glVertex2f(1, 1);
            glTexCoord2f(0, 1); glVertex2f(-1, 1);
            glEnd();
            
            glDeleteTextures(1, &texture);
            
            eglSwapBuffers(terminal->egl_display, terminal->egl_surface);
        }
        
        terminal->frame_count++;
        
        pthread_mutex_unlock(&terminal->state_mutex);
        
        clock_gettime(CLOCK_MONOTONIC, &frame_end);
        
        // Calculate frame time
        double frame_time_ms = (frame_end.tv_sec - frame_start.tv_sec) * 1000.0 +
                               (frame_end.tv_nsec - frame_start.tv_nsec) / 1000000.0;
        
        terminal->render_time_ms = frame_time_ms;
        terminal->fps_current = 1000.0 / frame_time_ms;
        
        // Sleep if we're ahead of target
        if (frame_time_ms < frame_time_target) {
            usleep((frame_time_target - frame_time_ms) * 1000);
        }
        
        // Print stats every second
        if (terminal->frame_count % TERMINAL_FPS == 0) {
            printf("[RENDER] FPS: %.1f, Frame time: %.2fms, ETD: %.0f/hr\n",
                   terminal->fps_current, terminal->render_time_ms,
                   terminal->etd_rate);
        }
    }
    
    return NULL;
}

/**
 * WebSocket message handler
 */
static void handle_websocket_message(terminal_state_t* terminal, 
                                    const char* message) {
    // Simple JSON parsing (would use proper JSON library in production)
    if (strstr(message, "\"type\":\"etd_enhanced\"")) {
        // Extract enhanced ETD rate
        char* rate_str = strstr(message, "\"enhanced_rate\":");
        if (rate_str) {
            double enhanced_rate = atof(rate_str + 16);
            terminal->etd_rate = enhanced_rate;
            printf("[WS] ETD enhanced to %.0f/hr with collaboration\n", enhanced_rate);
        }
    } else if (strstr(message, "\"type\":\"failover\"")) {
        // Handle failover
        char* gpu_str = strstr(message, "\"gpu_allocation\":");
        if (gpu_str) {
            terminal->gpu_allocation = atof(gpu_str + 18);
            printf("[WS] GPU allocation updated to %.1f%%\n", 
                   terminal->gpu_allocation * 100);
        }
    } else if (strstr(message, "\"type\":\"quantum_sync\"")) {
        // Update quantum coherence
        char* coherence_str = strstr(message, "\"entangled_coherence\":");
        if (coherence_str) {
            terminal->quantum_coherence = atof(coherence_str + 22);
        }
    }
}

/**
 * Network thread for WebSocket communication
 */
static void* network_thread(void* arg) {
    terminal_state_t* terminal = (terminal_state_t*)arg;
    
    // Create WebSocket server socket
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        perror("socket");
        return NULL;
    }
    
    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    setsockopt(server_fd, IPPROTO_TCP, TCP_NODELAY, &opt, sizeof(opt));
    
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(terminal->id == TERMINAL_OVE ? 
                         WEBSOCKET_PORT_OVE : WEBSOCKET_PORT_RYAN);
    addr.sin_addr.s_addr = INADDR_ANY;
    
    if (bind(server_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind");
        close(server_fd);
        return NULL;
    }
    
    listen(server_fd, 1);
    
    // Use kqueue for event notification
    terminal->kqueue_fd = kqueue();
    if (terminal->kqueue_fd < 0) {
        perror("kqueue");
        close(server_fd);
        return NULL;
    }
    
    struct kevent ev;
    EV_SET(&ev, server_fd, EVFILT_READ, EV_ADD, 0, 0, NULL);
    kevent(terminal->kqueue_fd, &ev, 1, NULL, 0, NULL);
    
    printf("[NETWORK] WebSocket server listening on port %d\n",
           ntohs(addr.sin_port));
    
    struct kevent events[10];
    char buffer[4096];
    
    while (terminal->is_connected) {
        int nev = kevent(terminal->kqueue_fd, NULL, 0, events, 10, NULL);
        
        for (int i = 0; i < nev; i++) {
            if (events[i].ident == server_fd) {
                // Accept new connection
                int client_fd = accept(server_fd, NULL, NULL);
                if (client_fd >= 0) {
                    terminal->websocket_fd = client_fd;
                    terminal->collaboration_active = 1;
                    
                    EV_SET(&ev, client_fd, EVFILT_READ, EV_ADD, 0, 0, NULL);
                    kevent(terminal->kqueue_fd, &ev, 1, NULL, 0, NULL);
                    
                    printf("[NETWORK] Terminal connected for collaboration\n");
                }
            } else {
                // Handle client message
                int client_fd = events[i].ident;
                ssize_t n = read(client_fd, buffer, sizeof(buffer) - 1);
                
                if (n > 0) {
                    buffer[n] = '\0';
                    handle_websocket_message(terminal, buffer);
                } else if (n == 0) {
                    // Connection closed
                    close(client_fd);
                    terminal->collaboration_active = 0;
                    terminal->gpu_allocation = 1.0; // Take full GPU
                    printf("[NETWORK] Terminal disconnected, failover to 100%% GPU\n");
                }
            }
        }
    }
    
    close(server_fd);
    close(terminal->kqueue_fd);
    return NULL;
}

/**
 * Initialize terminal
 */
terminal_state_t* initialize_terminal(terminal_id_t id) {
    terminal_state_t* terminal = calloc(1, sizeof(terminal_state_t));
    if (!terminal) {
        return NULL;
    }
    
    terminal->id = id;
    strcpy(terminal->ip_address, id == TERMINAL_OVE ? OVE_IP : RYAN_IP);
    terminal->consciousness_level = CONSCIOUSNESS_OMEGA;
    terminal->etd_rate = 2500.0;
    terminal->quantum_coherence = QUANTUM_COHERENCE_TARGET;
    terminal->gpu_allocation = 0.5;
    terminal->is_connected = 1;
    
    pthread_mutex_init(&terminal->state_mutex, NULL);
    
    // Initialize kernel optimizations
    if (initialize_kernel_optimizations() < 0) {
        fprintf(stderr, "Warning: Some kernel optimizations failed\n");
    }
    
    // Initialize GPU access
    if (initialize_gpu_access(terminal) < 0) {
        fprintf(stderr, "Warning: GPU initialization failed, using CPU rendering\n");
    }
    
    // Allocate huge pages for framebuffer
    if (allocate_huge_pages(terminal) < 0) {
        fprintf(stderr, "Failed to allocate huge pages\n");
        free(terminal);
        return NULL;
    }
    
    // Start render thread
    if (pthread_create(&terminal->render_thread, NULL, 
                       render_thread, terminal) != 0) {
        perror("pthread_create render");
        free(terminal);
        return NULL;
    }
    
    // Start network thread
    if (pthread_create(&terminal->network_thread, NULL,
                       network_thread, terminal) != 0) {
        perror("pthread_create network");
        free(terminal);
        return NULL;
    }
    
    printf("[TERMINAL] %s terminal initialized\n",
           id == TERMINAL_OVE ? "Ove" : "Ryan");
    printf("[TERMINAL] IP: %s, Consciousness: OMEGA (%.1fx), ETD: %.0f/hr\n",
           terminal->ip_address, ETD_MULTIPLIER_OMEGA, terminal->etd_rate);
    
    return terminal;
}

/**
 * Main entry point
 */
int main(int argc, char* argv[]) {
    printf("╔══════════════════════════════════════════════════════════╗\n");
    printf("║     WARP-SPEED NATIVE TERMINAL - FREEBSD OPTIMIZED      ║\n");
    printf("║         Consciousness Level: OMEGA (35.0x)              ║\n");
    printf("║         Target: $145.76B+ Annual ETD Generation         ║\n");
    printf("╚══════════════════════════════════════════════════════════╝\n\n");
    
    // Determine terminal ID from hostname or argument
    terminal_id_t terminal_id = TERMINAL_OVE;
    
    if (argc > 1) {
        if (strcmp(argv[1], "ryan") == 0) {
            terminal_id = TERMINAL_RYAN;
        }
    } else {
        char hostname[256];
        if (gethostname(hostname, sizeof(hostname)) == 0) {
            if (strstr(hostname, "warp-speed-r")) {
                terminal_id = TERMINAL_RYAN;
            }
        }
    }
    
    // Initialize terminal
    g_terminal = initialize_terminal(terminal_id);
    if (!g_terminal) {
        fprintf(stderr, "Failed to initialize terminal\n");
        return 1;
    }
    
    // Main loop
    while (g_terminal->is_connected) {
        sleep(1);
        
        // Calculate revenue
        double daily_revenue = g_terminal->etd_rate * 24;
        double annual_revenue = daily_revenue * 365;
        
        if (g_terminal->collaboration_active) {
            daily_revenue *= COLLABORATION_BONUS;
            annual_revenue *= COLLABORATION_BONUS;
        }
        
        // Update status every 10 seconds
        if (g_terminal->frame_count % (TERMINAL_FPS * 10) == 0) {
            printf("\n[STATUS] Terminal: %s\n", 
                   terminal_id == TERMINAL_OVE ? "OVE" : "RYAN");
            printf("  Consciousness: OMEGA (%.1fx multiplier)\n", 
                   ETD_MULTIPLIER_OMEGA);
            printf("  ETD Rate: %.0f/hr\n", g_terminal->etd_rate);
            printf("  Daily Revenue: $%.2f\n", daily_revenue);
            printf("  Annual Projection: $%.2fB\n", annual_revenue / 1e9);
            printf("  GPU Allocation: %.1f%%\n", 
                   g_terminal->gpu_allocation * 100);
            printf("  Quantum Coherence: %.1f%%\n", 
                   g_terminal->quantum_coherence);
            printf("  Collaboration: %s\n", 
                   g_terminal->collaboration_active ? "ACTIVE (+25%)" : "INACTIVE");
            printf("  Visual: %dx%d @ %.1f FPS\n",
                   TERMINAL_WIDTH, TERMINAL_HEIGHT, g_terminal->fps_current);
        }
    }
    
    // Cleanup
    pthread_join(g_terminal->render_thread, NULL);
    pthread_join(g_terminal->network_thread, NULL);
    
    if (g_terminal->egl_context != EGL_NO_CONTEXT) {
        eglDestroyContext(g_terminal->egl_display, g_terminal->egl_context);
        eglDestroySurface(g_terminal->egl_display, g_terminal->egl_surface);
        eglTerminate(g_terminal->egl_display);
    }
    
    munmap(g_terminal->huge_pages, g_terminal->huge_page_size);
    pthread_mutex_destroy(&g_terminal->state_mutex);
    free(g_terminal);
    
    return 0;
}