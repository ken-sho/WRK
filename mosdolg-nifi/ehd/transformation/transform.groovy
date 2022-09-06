import org.apache.nifi.controller.ControllerService
import groovy.sql.Sql

def flowFile = session.get()
if (flowFile == null) {
    return
}

def lookup = context.controllerServiceLookup
def dbServiceName = dbPoolName.value
def sqlStatement = SQLStatement.evaluateAttributeExpressions(flowFile).value
def dbcpServiceId = lookup.getControllerServiceIdentifiers(ControllerService).find {
    cs -> lookup.getControllerServiceName(cs) == dbServiceName
}

def conn = lookup.getControllerService(dbcpServiceId)?.getConnection()
try {
    flowFile = session.write(flowFile, {outputStream ->
        def sql = new Sql(conn)

        sql.execute(sqlStatement)

    } as OutputStreamCallback)

    session.transfer(flowFile, REL_SUCCESS)
} catch(e) {
    log.error('Scripting error', e)
    session.transfer(flowFile, REL_FAILURE)
}

conn?.close()
