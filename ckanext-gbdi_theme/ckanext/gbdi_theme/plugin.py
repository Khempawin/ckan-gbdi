import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit

def get_group_title(id):
    import ckan.model as model
    title = ''
    title = model.Session.query(model.Group.title).\
        filter(model.Group.id == id).all()
    return title

class GbdiThemePlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)

    plugins.implements(plugins.ITemplateHelpers)
    # IConfigurer

    def update_config(self, config_):
        toolkit.add_template_directory(config_, 'templates')
        toolkit.add_public_directory(config_, 'public')
        toolkit.add_resource('fanstatic',
            'gbdi_theme')

    def get_helpers(self):
        '''Register the most_popular_groups() function above as a template
        helper function.

        '''
        # Template helper function names should begin with the name of the
        # extension they belong to, to avoid clashing with functions from
        # other extensions.
        return {'gbdi_theme_get_group_title': get_group_title}
