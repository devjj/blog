// Main JavaScript file
console.log('Blog loaded');

// Add any interactive features here
document.addEventListener('DOMContentLoaded', () => {
  // Highlight current page in navigation
  const currentPath = window.location.pathname;
  const navLinks = document.querySelectorAll('nav a');
  
  navLinks.forEach(link => {
    if (link.getAttribute('href') === currentPath) {
      link.classList.add('active');
    }
  });
});