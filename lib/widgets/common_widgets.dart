import 'package:flutter/material.dart';
import '../config/theme_config.dart';

/// Componente para mostrar información en formato de tarjeta
class InfoCard extends StatelessWidget {
  final String title;
  final List<InfoItem> items;
  final List<Widget>? actions;
  final bool withGradient;

  const InfoCard({
    super.key,
    required this.title,
    required this.items,
    this.actions,
    this.withGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ThemeConfig.getCardDecoration(withGradient: withGradient),
      child: Padding(
        padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: ThemeConfig.headingSmall),
            const SizedBox(height: ThemeConfig.paddingMedium),
            ...items.map((item) => _buildInfoItem(item)),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: ThemeConfig.paddingLarge),
              Wrap(
                spacing: ThemeConfig.paddingSmall,
                runSpacing: ThemeConfig.paddingSmall,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(InfoItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ThemeConfig.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.icon != null) ...[
            Icon(item.icon, color: ThemeConfig.textSecondaryColor, size: 20),
            const SizedBox(width: ThemeConfig.paddingMedium),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: ThemeConfig.caption),
                const SizedBox(height: 4),
                item.widget ??
                    Text(item.value ?? '', style: ThemeConfig.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Elemento de información para InfoCard
class InfoItem {
  final String label;
  final String? value;
  final IconData? icon;
  final Widget? widget;

  InfoItem({required this.label, this.value, this.icon, this.widget});
}

/// Componente para lista de elementos con estilo consistente
class StyledListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const StyledListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: ThemeConfig.paddingMedium,
            vertical: ThemeConfig.paddingSmall,
          ),
          decoration: ThemeConfig.getCardDecoration(),
          child: ListTile(
            leading: leading,
            title: Text(title, style: ThemeConfig.bodyLarge),
            subtitle:
                subtitle != null
                    ? Text(subtitle!, style: ThemeConfig.bodySmall)
                    : null,
            trailing: trailing,
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ThemeConfig.paddingMedium,
              vertical: ThemeConfig.paddingSmall,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ThemeConfig.radiusLarge),
            ),
          ),
        ),
      ],
    );
  }
}

/// Componente para botones de acción estilizados
class ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final ActionButtonType type;
  final bool isLoading;

  const ActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.type = ActionButtonType.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    ButtonStyle style;
    switch (type) {
      case ActionButtonType.primary:
        style = ThemeConfig.getPrimaryButtonStyle();
        break;
      case ActionButtonType.secondary:
        style = ThemeConfig.getSecondaryButtonStyle();
        break;
      case ActionButtonType.danger:
        style = ThemeConfig.getDangerButtonStyle();
        break;
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon:
          isLoading
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(icon, size: 18),
      label: Text(text),
      style: style,
    );
  }
}

enum ActionButtonType { primary, secondary, danger }

/// Componente para mostrar estados vacíos
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ThemeConfig.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
              decoration: BoxDecoration(
                color: ThemeConfig.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: ThemeConfig.primaryColor),
            ),
            const SizedBox(height: ThemeConfig.paddingLarge),
            Text(title, style: ThemeConfig.headingMedium),
            const SizedBox(height: ThemeConfig.paddingSmall),
            Text(
              message,
              style: ThemeConfig.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: ThemeConfig.paddingLarge),
              ActionButton(
                text: actionText!,
                icon: Icons.add,
                onPressed: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Componente para mostrar estados de error
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ThemeConfig.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(ThemeConfig.paddingLarge),
              decoration: BoxDecoration(
                color: ThemeConfig.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: ThemeConfig.errorColor,
              ),
            ),
            const SizedBox(height: ThemeConfig.paddingLarge),
            Text(title, style: ThemeConfig.headingMedium),
            const SizedBox(height: ThemeConfig.paddingSmall),
            Text(
              message,
              style: ThemeConfig.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: ThemeConfig.paddingLarge),
              ActionButton(
                text: actionText!,
                icon: Icons.refresh,
                onPressed: onAction!,
                type: ActionButtonType.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Componente para mostrar estados de carga
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.primaryColor),
          ),
          if (message != null) ...[
            const SizedBox(height: ThemeConfig.paddingMedium),
            Text(
              message!,
              style: ThemeConfig.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Componente para input de búsqueda estilizado
class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SearchInput({
    super.key,
    required this.controller,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(ThemeConfig.paddingMedium),
      child: TextFormField(
        controller: controller,
        decoration: ThemeConfig.getInputDecoration(
          labelText: '',
          hintText: hintText,
          prefixIcon: Icons.search,
          suffixIcon:
              controller.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      onClear?.call();
                    },
                  )
                  : null,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Componente para FAB personalizado
class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  const CustomFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: ThemeConfig.primaryColor,
      foregroundColor: Colors.white,
      elevation: ThemeConfig.elevationMedium,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}

/// Componente para mostrar snackbars estilizados
class SnackBarHelper {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: ThemeConfig.paddingSmall),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeConfig.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
        ),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: ThemeConfig.paddingSmall),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeConfig.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
        ),
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: ThemeConfig.paddingSmall),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeConfig.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
        ),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: ThemeConfig.paddingSmall),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ThemeConfig.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConfig.radiusMedium),
        ),
      ),
    );
  }
}
