"""Figuras del README, generadas con datos sintéticos.

Las curvas reproducen la FORMA de los patrones observados en la operación real
(ventas concentradas al principio, con cola larga), con parámetros redondeados
y ruido de muestreo: ningún punto coincide con un valor real.
"""
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import fsolve

rng = np.random.default_rng(42)
OUT = Path(__file__).resolve().parent.parent / "figures"
OUT.mkdir(exist_ok=True)

INK, MUTED, GRID, LINE = "#1a1d21", "#5b6370", "#e3e7ec", "#1f5fbf"
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10})


def estilo(ax, titulo, xlabel, nota):
    ax.set_title(titulo, loc="left", color=INK, fontsize=12, fontweight="bold")
    ax.set_xlabel(xlabel, color=MUTED)
    ax.set_ylabel("Ventas acumuladas (%)", color=MUTED)
    ax.set_ylim(0, 102)
    ax.text(0, -0.24, nota, transform=ax.transAxes, color=MUTED, fontsize=8)
    ax.grid(axis="y", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    for s in ("left", "bottom"):
        ax.spines[s].set_color(GRID)
    ax.tick_params(colors=MUTED, length=0)


# ---------------------------------------------------------------------------
# Figura 1: ventas acumuladas según los días hábiles en gestión (vista del CRM)
# CDF logarítmica F(t) = log(1 + a t) / log(1 + a H), con F(1) ≈ 0.5 y F(6.5) ≈ 0.8
# ---------------------------------------------------------------------------
def cdf(t, a, h):
    return np.log1p(a * t) / np.log1p(a * h)


a, h = fsolve(lambda p: [cdf(1, *p) - 0.5, cdf(6.5, *p) - 0.8], x0=[5.0, 40.0])
u = rng.uniform(size=600)
t_venta = np.expm1(u * np.log1p(a * h)) / a           # días hábiles hasta la venta
dias = np.arange(0, 31)
acum_dias = np.array([(t_venta <= d).mean() for d in dias]) * 100

fig, ax = plt.subplots(figsize=(7.2, 3.8), dpi=200)
ax.plot(dias, acum_dias, color=LINE, linewidth=2)
ax.fill_between(dias, acum_dias, 0, where=dias <= 7, color=LINE, alpha=0.08, linewidth=0)
for d, txt, off in ((1, "la mitad el primer día", (3, -14)), (7, "cerca del 80% en la\nprimera semana", (10.5, -24))):
    y = acum_dias[d]
    ax.plot([d], [y], "o", color=LINE, markersize=7, markeredgecolor="white", markeredgewidth=2, zorder=3)
    ax.annotate(txt, xy=(d, y), xytext=(off[0], y + off[1]), color=INK, fontsize=10,
                arrowprops=dict(arrowstyle="-", color=MUTED, linewidth=0.8))
ax.set_xlim(0, 30)
estilo(ax, "Primera mirada: un lead pierde valor rápido",
       "Días hábiles desde que el lead entra en gestión",
       "Datos sintéticos que reproducen la forma del patrón observado en el CRM.")
fig.tight_layout()
fig.savefig(OUT / "ventas_por_dia.png", bbox_inches="tight", facecolor="white")
plt.close(fig)

# ---------------------------------------------------------------------------
# Figura 2: ventas acumuladas según el intento en que se concretaron (matriz k)
# ---------------------------------------------------------------------------
p_intento = np.array([0.50, 0.32, 0.09, 0.04, 0.025, 0.015, 0.01])
intento_venta = rng.choice(np.arange(1, 8), size=600, p=p_intento)
intentos = np.arange(1, 9)
acum_k = np.array([(intento_venta <= k).mean() for k in intentos]) * 100

fig, ax = plt.subplots(figsize=(7.2, 3.8), dpi=200)
ax.plot(np.r_[0, intentos], np.r_[0, acum_k], color=LINE, linewidth=2)
ax.plot(intentos, acum_k, "o", color=LINE, markersize=7, markeredgecolor="white", markeredgewidth=2, zorder=3)
for k, txt, off in ((1, "la mitad en el\nprimer intento", (1.6, -22)), (2, "más del 80% en los\ndos primeros", (3.0, -22))):
    y = acum_k[k - 1]
    ax.annotate(txt, xy=(k, y), xytext=(off[0], y + off[1]), color=INK, fontsize=10,
                arrowprops=dict(arrowstyle="-", color=MUTED, linewidth=0.8))
ax.set_xlim(0, 8)
ax.set_xticks(intentos)
estilo(ax, "Con el historial de llamadas: el valor está en los primeros intentos",
       "Intento de llamada en el que se concretó la venta",
       "Datos sintéticos que reproducen la forma del patrón observado en la matriz de intentos.")
fig.tight_layout()
fig.savefig(OUT / "ventas_por_intento.png", bbox_inches="tight", facecolor="white")
plt.close(fig)

print(f"días: d1={acum_dias[1]:.1f}%  d5={acum_dias[5]:.1f}%  d7={acum_dias[7]:.1f}%")
print("intentos:", " ".join(f"k{k}={v:.1f}%" for k, v in zip(intentos, acum_k)))
