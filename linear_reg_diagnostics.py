# reference: https://www.statsmodels.org/dev/examples/notebooks/generated/linear_regression_diagnostics_plots.html
import numpy as np
import seaborn as sns
import pandas as pd
from statsmodels.tools.tools import maybe_unwrap_results
from statsmodels.graphics.gofplots import ProbPlot
from statsmodels.stats.outliers_influence import variance_inflation_factor
import matplotlib.pyplot as plt
import statsmodels
import statsmodels.api as sm
from typing import Type

style_talk = 'seaborn-talk'    #refer to plt.style.available

class Linear_Reg_Diagnostics():
    """
    Diagnostic plots to identify potential problems in a linear regression fit.
    Including:
        a. Omitted variables
        b. Correlation among residuals
        c. Heteroskedasticity
        d. Outliers
        e. Influential observations with high leverage
        f. Multicollinearity
    """

    def __init__(self,
                 results: Type[statsmodels.regression.linear_model.RegressionResultsWrapper]) -> None:
        """
        For a linear regression model, generates following diagnostic plots:

        a. residual vs y -> any trend in the residuals?
        b. qq plot -> do the residuals follow a normal distribution?
        c. Studentized residuals vs y -> heteroskedasticity?
        d. cook's distance -> are there any influential observations?

        and a VIF table -> are there any multicollinearity?

        Args:
            results (Type[statsmodels.regression.linear_model.RegressionResultsWrapper]):
                must be instance of statsmodels.regression.linear_model object

        Raises:
            TypeError: if instance does not belong to above object

        Example:
        >>> import numpy as np
        >>> import pandas as pd
        >>> import statsmodels.formula.api as smf
        >>> x = np.linspace(-np.pi, np.pi, 100)
        >>> y = 3*x + 8 + np.random.normal(0,1, 100)
        >>> df = pd.DataFrame({'x':x, 'y':y})
        >>> res = smf.ols(formula= "y ~ x", data=df).fit()
        >>> cls = Linear_Reg_Diagnostic(res)
        >>> cls(plot_context="seaborn-paper")

        In case you do not need all plots you can also independently make an individual plot/table
        in following ways

        >>> cls = Linear_Reg_Diagnostic(res)
        >>> cls.residual_plot()
        >>> cls.qq_plot()
        >>> cls.scale_location_plot()
        >>> cls.leverage_plot()
        >>> cls.vif_table()
        """

        if isinstance(results, statsmodels.regression.linear_model.RegressionResultsWrapper) is False:
            raise TypeError("result must be instance of statsmodels.regression.linear_model.RegressionResultsWrapper object")

        self.results = maybe_unwrap_results(results)

        self.y_true = self.results.model.endog
        self.y_predict = self.results.fittedvalues
        self.xvar = self.results.model.exog
        self.xvar_names = self.results.model.exog_names

        self.residual = np.array(self.results.resid)
        influence = self.results.get_influence()
        self.residual_norm = influence.resid_studentized_internal
        self.leverage = influence.hat_matrix_diag
        self.cooks_distance = influence.cooks_distance[0]
        self.nparams = len(self.results.params)

    def __call__(self, plot_context='seaborn-paper'):
        # print(plt.style.available)
        with plt.style.context(plot_context):
            fig, ax = plt.subplots(nrows=2, ncols=2, figsize=(10,10))
            self.residual_plot(ax=ax[0,0])
            self.qq_plot(ax=ax[0,1])
            self.scale_location_plot(ax=ax[1,0])
            self.leverage_plot(ax=ax[1,1])
            plt.show()

        self.vif_table()
        return fig, ax


    def residual_plot(self, ax=None):
        """
        Studentized Residual vs Fitted Plot # replaced residuals with Studentized residuals

        Graphical way to identify non-linearity or trend in residuals
        95% of residuals should fall within +- 2 SD
        """
        if ax is None:
            fig, ax = plt.subplots()

        ax.scatter(self.y_predict, self.residual_norm, alpha=0.5);
        sns.regplot(
            x=self.y_predict,
            y=self.residual_norm,
            scatter=False, ci=False,
            lowess=True,
            line_kws={'color': 'red', 'lw': 1, 'alpha': 0.8},
            ax=ax)
        
        ax.axhspan(-2, 2, facecolor='green', alpha=0.2)
        ax.axhline(0, color='black', lw=1, ls = '--')

        # annotations
        # abs_sq_norm_resid = np.flip(np.argsort(self.residual_norm), 0)
        # abs_sq_norm_resid_top_3 = abs_sq_norm_resid[:3]
        # for i in abs_sq_norm_resid_top_3:
        #     ax.annotate(
        #         i,
        #         xy=(self.y_predict[i], self.residual_norm[i]),
        #         color='C3')
        ax.set_title('Studentized Residuals vs Fitted', fontweight="bold")
        ax.set_xlabel('Fitted values')
        ax.set_ylabel('Studentized Residuals (95% between +- 2 sd)');
        return ax

    def qq_plot(self, ax=None):
        """
        Standarized Residual vs Theoretical Quantile plot

        Used to visually check if residuals are normally distributed.
        Points spread along the diagonal line will suggest so.
        """
        if ax is None:
            fig, ax = plt.subplots()

        QQ = ProbPlot(self.residual_norm)
        QQ.qqplot(line='45', alpha=0.5, lw=1, ax=ax)

        # annotations
        # abs_norm_resid = np.flip(np.argsort(np.abs(self.residual_norm)), 0)
        # abs_norm_resid_top_3 = abs_norm_resid[:3]
        # for r, i in enumerate(abs_norm_resid_top_3):
        #     ax.annotate(
        #         i,
        #         xy=(np.flip(QQ.theoretical_quantiles, 0)[r], self.residual_norm[i]),
        #         ha='right', color='C3')
        jb = statsmodels.stats.stattools.jarque_bera(self.residual)
        ax.set_title(f'Q-Q plot (JB = {jb[0]:0.2f}, p-value = {jb[1]:0.2f})', fontweight="bold")
        ax.set_xlabel('Z scores')
        ax.set_ylabel('Studentized Residuals')
        return ax

    def scale_location_plot(self, ax=None):
        """
        Sqrt(Abs(Standarized Residual)) vs Fitted values plot

        To check homoscedasticity of the residuals.
        Horizontal line will suggest so.
        """
        if ax is None:
            fig, ax = plt.subplots()

        residual_norm_abs_sqrt = np.sqrt(np.abs(self.residual_norm))

        ax.scatter(self.y_predict, residual_norm_abs_sqrt, alpha=0.5);
        sns.regplot(
            x=self.y_predict,
            y=residual_norm_abs_sqrt,
            scatter=False, ci=False,
            lowess=True,
            line_kws={'color': 'red', 'lw': 1, 'alpha': 0.8},
            ax=ax)

        # annotations
        # abs_sq_norm_resid = np.flip(np.argsort(residual_norm_abs_sqrt), 0)
        # abs_sq_norm_resid_top_3 = abs_sq_norm_resid[:3]
        # for i in abs_sq_norm_resid_top_3:
        #     ax.annotate(
        #         i,
        #         xy=(self.y_predict[i], residual_norm_abs_sqrt[i]),
        #         color='C3')
        lb = sm.stats.acorr_ljungbox(self.residual)
        ax.set_title(f'Scale-Location (LB = {lb.iloc[-1,0]:0,.0f}, p-value = {lb.iloc[-1,-1]:0.2f})', fontweight="bold")
        ax.set_xlabel('Fitted values')
        ax.set_ylabel(r'$\sqrt{|\mathrm{Studentized\ Residuals}|}$');
        return ax

    def leverage_plot(self, ax=None):
        """
        Studentized Residual vs Leverage plot

        Points falling outside Cook's distance curves are considered influential observations which can impact 
        the regression parameter estimation.
        Good to have none outside the curves.
        """
        if ax is None:
            fig, ax = plt.subplots()

        ax.scatter(
            self.leverage,
            self.residual_norm,
            alpha=0.5);

        sns.regplot(
            x=self.leverage,
            y=self.residual_norm,
            scatter=False,
            ci=False,
            lowess=True,
            line_kws={'color': 'red', 'lw': 1, 'alpha': 0.8},
            ax=ax)

        # annotations
        # leverage_top_3 = np.flip(np.argsort(self.cooks_distance), 0)[:3]
        # for i in leverage_top_3:
        #     ax.annotate(
        #         i,
        #         xy=(self.leverage[i], self.residual_norm[i]),
        #         color = 'C3')

        xtemp, ytemp = self.__cooks_dist_line(0.5) # 0.5 line
        ax.plot(xtemp, ytemp, label="Cook's distance = 0.5", lw=1, ls='-', color='red') # fixed
        xtemp, ytemp = self.__cooks_dist_line(1) # 1 line
        ax.plot(xtemp, ytemp, label="Cook's distance = 1", lw=1, ls='--', color='red') # fixed

        ax.set_xlim(0, max(self.leverage)*1.1)
        ax.set_title('Studentized Residuals vs Leverage', fontweight="bold")
        ax.set_xlabel('Leverage')
        ax.set_ylabel('Studentized Residuals')
        ax.legend(loc='upper right')
        return ax

    def vif_table(self):
        """
        VIF table

        VIF, the variance inflation factor, is a measure of multicollinearity.
        VIF > 5 for a variable indicates that it is highly collinear with the
        other input variables.
        """
        vif_df = pd.DataFrame()
        vif_df["Features"] = self.xvar_names[1:] # exclude intercept
        vif_df["VIF Factor"] = [variance_inflation_factor(self.xvar, i) for i in range(self.xvar.shape[1]) if i != 0]

        print(vif_df
                .sort_values("VIF Factor")
                .round(2))


    def __cooks_dist_line(self, factor):
        """
        Helper function for plotting Cook's distance curves
        """
        p = self.nparams
        formula = lambda x: np.sqrt((factor * p * (1 - x)) / x)
        x = np.linspace(min(self.leverage), max(self.leverage), 50)
        y = formula(x)
        return x, y