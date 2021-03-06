## ---- include = FALSE----------------------------------------------------

##-------------------------------------------
## Definições knitr
library(knitr)

opts_chunk$set(
    cache = FALSE,
    fig.path = "figures/",
    cache.path = "cache/",
    fig.align = "center",
    dev.args = list(family = "Palatino")
    )

##-------------------------------------------
## Definições lattice
library(lattice)
library(latticeExtra)

ps <- list(
    box.rectangle = list(fill = c("gray70")),
    box.umbrella = list(lty = 1),
    dot.symbol = list(pch = 19),
    dot.line = list(col = "gray50", lty = 3),
    plot.symbol = list(pch = 19),
    strip.background = list(col = c("gray80", "gray50"))
    )
trellis.par.set(ps)


## ------------------------------------------------------------------------

## Carrega o conjunto de dados
load("capulhos.rda")
str(capulhos)


## ------------------------------------------------------------------------

## Visualizando graficamente
xyplot(ncapu ~ dexp, data = capulhos,
       jitter.x = TRUE, grid = TRUE)

## Verificando a relação média-variância
aggregate(ncapu ~ dexp, data = capulhos,
          FUN = function(x)
              c("Média" = mean(x), "Variância" = var(x)))


## ------------------------------------------------------------------------

## Preditores Considerados
f0 <- ncapu ~ 1
f1 <- ncapu ~ dexp
f2 <- ncapu ~ dexp + I(dexp^2)

## Ajustando os modelos Poisson
m0P <- glm(f0, data = capulhos, family = poisson)
m1P <- glm(f1, data = capulhos, family = poisson)
m2P <- glm(f2, data = capulhos, family = poisson)

## Ajustando os modelos Quasi-Poisson
m0Q <- glm(f0, data = capulhos, family = quasipoisson)
m1Q <- glm(f1, data = capulhos, family = quasipoisson)
m2Q <- glm(f2, data = capulhos, family = quasipoisson)


## ------------------------------------------------------------------------

## Testes de razão de verossimilhanças
anova(m0P, m1P, m2P, test = "Chisq")
anova(m0Q, m1Q, m2Q, test = "Chisq")


## ------------------------------------------------------------------------

## Estimativas dos parâmetros
## lapply(list("Poisson" = m2P, "Quasi" = m2Q),
##        function(x) cbind("Est" = coef(x), "SE" = sqrt(diag(vcov(x)))))
## coefcbind(coef(summary(m2P))[, 1:2], coef(summary(m2Q))[, 1:2])
car::compareCoefs(m2P, m2Q)


## ------------------------------------------------------------------------

## Resumo do modelo
summary(m2Q)


## ------------------------------------------------------------------------

## Gráficos padrão, cuidado!
par(mfrow = c(2, 3))
plot(m2Q, which = 1:6)

## Análise de diagnóstico
boot::glm.diag.plots(m2Q)

## Gráficos qauntil-quantil com envelopes simulados
hnp::hnp(m2P)
## hnp::hnp(m2Q) ## Verificar 


## ------------------------------------------------------------------------

## Predição
pred <- data.frame(dexp = with(capulhos,
                               seq(min(dexp), max(dexp), l = 50)))
qn <- qnorm(0.975)

## pela Poisson
aux <- predict(m2P, newdata = pred, se.fit = TRUE)
aux <- with(aux, fit + se.fit %*%
                 cbind(Plwr = -1, Pfit = 0, Pupr = 1) * qn)
pred <- cbind(pred, exp(aux))

## pela Quasi-Poisson
aux <- predict(m2Q, newdata = pred, se.fit = TRUE)
aux <- with(aux, fit + se.fit %*%
                 cbind(Qlwr = -1, Qfit = 0, Qupr = 1) * qn)
pred <- cbind(pred, exp(aux))

xyplot(ncapu ~ dexp, data = capulhos,
       jitter.x = TRUE,
       key = list(lines = list(lty = 1, lwd = 2, col = 1:2),
                  text = list(c("Poisson", "Quasi-Poisson")))
       ) +
    as.layer(
        xyplot(Pfit + Plwr + Pupr ~ dexp, data = pred,
               type = "l", col = 1, lty = c(1, 3, 3), lwd = 2)
    ) +
    as.layer(
        xyplot(Qfit + Qlwr + Qupr ~ dexp, data = pred,
               type = "l", col = 2, lty = c(1, 2, 2), lwd = 2)
    )


