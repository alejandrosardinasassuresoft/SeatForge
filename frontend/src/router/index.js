import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import('@/pages/HomePage.vue'),
    meta: { title: 'Home' },
  },
  {
    path: '/dashboard',
    name: 'operations-dashboard',
    component: () => import('@/pages/DashboardView.vue'),
    meta: { title: 'Operations Dashboard' },
  },
  {
    path: '/my-registrations',
    name: 'my-registrations',
    component: () => import('@/pages/MyRegistrationsView.vue'),
    meta: { title: 'My Registrations' },
  },
  {
    path: '/workshops',
    name: 'catalog',
    component: () => import('@/pages/CatalogView.vue'),
    meta: { title: 'Workshop Catalog' },
  },
  {
    path: '/sessions/:id',
    name: 'session-detail',
    component: () => import('@/pages/SessionDetailView.vue'),
    meta: { title: 'Session Details' },
  },
  {
    path: '/about',
    name: 'about',
    component: () => import('@/pages/AboutPage.vue'),
    meta: { title: 'About' },
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/pages/NotFoundPage.vue'),
    meta: { title: 'Not Found' },
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to) => {
  document.title = to.meta.title ? `${to.meta.title} — SeatForge` : 'SeatForge'
})

export default router
