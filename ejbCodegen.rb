# Code generator for Entity beans
# Amol Dharmadhikari <amol.dharmadhikari@gmail.com>

# Bean variable class
# Stores the variable names and their types
class BeanVariable
    attr_accessor :name, :type, :isprimary
    def initialize(name="", type=-1, isprimary=false)
        @name, @type, @isprimary = name, type, isprimary
    end

    def to_s
        s = ""
        s += "Variable name: " + @name + ", "
        s += "Variable type: " + @type + ", "
        if @isprimary
            s += "Is primary: Yes\n"
        else
            s += "Is primary: No\n"
        end
    end
end

# Package information as a list of directories in their hierarchical order
class PackageInfo
    attr_accessor :pkgName, :pkgLst
    def initialize(pkgName)
        @pkgName = pkgName
        @pkgLst = []
    end

    def to_s
        s = ""
        s += @pkgName + " "
        s += @pkgLst.to_s
    end
end

# CodeGenerator class
class CodeGenerator
    attr_accessor :directory, :beanName, :nameList, :typeList, :pkList
    attr_accessor :numFields, :beanPath, :pkgInfo, :metainfDir, :metainfPath

    def initialize(filename, pkgInfo, varlist=[])
        @nameList = []
        @typeList = []
        @pkList = []
        @numFields = 0
        @beanPath = nil
        @pkgInfo = pkgInfo
        @metainfDir = nil
        varlist.each do |var|
            @nameList << var.name
            @typeList << var.type
            @pkList << var.isprimary
        end
        @numFields = varlist.size
        @beanName = filename.split(".")[0]
        @directory = Dir.pwd
        @metainfPath = ""
    end
    
    # Generate code for the entity bean
    def generate
        generatePackageStructure
        generateHomeInterface
        generateRemoteInterface
        generateBeanClass
        generatePkClass
        generateEjbJarDotXml
        generateJawsDotXml
        generateJbossDotXml
    end

    # Generate the package structure from the current directory
    def generatePackageStructure
        puts "Generating the package structure ..."

        @beanPath = @directory.to_s
        
        # Create the bean directory
        @beanPath = File.join(@beanPath, @beanName)
        Dir.mkdir(@beanPath)
        
        # Create the meta-inf directory
        @metainfPath = File.join(@beanPath, "meta-inf")
        Dir.mkdir(@metainfPath)
        @metainfDir = Dir.new(@metainfPath)

        # Create the package structure below it
        @pkgInfo.pkgLst.each do |pkgdir|
            @beanPath = File.join(@beanPath, pkgdir)
            Dir.mkdir(@beanPath)
        end

        # Finally change to the innermost directory
        Dir.chdir(@beanPath)
        
    end

    # Generate the Home interface
    def generateHomeInterface
        puts "Generating the Home interface ..."

        homeclass = @beanName.capitalize + "Home"
        filename = homeclass + ".java"
        gencode = []
        
        # Headers
        gencode << "package " + @pkgInfo.pkgName + ";\n\n"
        gencode << "import java.rmi.*;\n"
        gencode << "import javax.ejb.*;\n\n"
        gencode << "public interface " << homeclass <<  \
            " extends javax.ejb.EJBHome {\n\n"
        
        # Create function
        gencode << "\tpublic " << @beanName.capitalize << " create("
        numFields.times do |num|
            name = @nameList[num]
            type = @typeList[num]
            
            gencode << type << " " << name
            if num < @numFields-1
                gencode << ", "
            end
        end
        gencode << ") throws javax.ejb.CreateException, " << \
            "javax.rmi.RemoteException;\n\n"
        
        # Find function
        gencode << "\tpublic " << @beanName.capitalize << \
            " findByPrimaryKey(" << @beanName.capitalize << "PK " << \
            @beanName << "pk) throws javax.rmi.RemoteException, " << \
            "javax.ejb.FinderException;\n\n"
        gencode << "}\n"
        
        writeCode(gencode, filename)
    end

    # Generate the Remote interface
    def generateRemoteInterface
        puts "Generating the Remote interface ..."

        remoteclass = @beanName.capitalize
        filename = remoteclass + ".java"
        gencode = []

        # Headers
        gencode << "package " << @pkgInfo.pkgName << ";\n\n"
        gencode << "import java.rmi.*;\n"
        gencode << "import javax.ejb.*;\n\n"
        gencode << "public interface " << remoteclass << \
            " extends javax.rmi.Remote, javax.ejb.EJBObject {\n\n"
        
        # Accessors and mutators
        @numFields.times do |num|
            name = @nameList[num]
            type = @typeList[num]
            
            gencode << "\tpublic " << type << " get" << name.capitalize << \
                "() throws java.rmi.RemoteException;\n\n"
            gencode << "\tpublic void set" << name.capitalize << "(" << \
                type << " " << name << ") throws java.rmi.RemoteException;\n\n"
        end
        gencode << "}\n"

        writeCode(gencode, filename)
    end

    # Generate the Bean Class
    def generateBeanClass
        puts "Generating the Bean Class ..."

        beanclass = @beanName.capitalize + "Bean"
        filename = beanclass + ".java"
        gencode = []

        # Headers
        gencode << "package " << @pkgInfo.pkgName << ";\n\n"
        gencode << "import java.rmi.*;\n"
        gencode << "import java.io.*;\n"
        gencode << "import javax.ejb.*;\n\n"
        gencode << "public class " << beanclass << \
            " implements javax.ejb.EntityBean {\n\n"

        # Data variables
        @numFields.times do |num|
            name = @nameList[num]
            type = @typeList[num]
            
            gencode << "\tpublic " << type << " " << name << ";\n"
        end
        gencode << "\n"
        
        # Constructor
        gencode << "\tpublic " << beanclass << "() {\n"
        gencode << "\t\tsuper();\n"
        gencode << "\t}\n\n"

        # ejbActivate
        gencode << "\tpublic void ejbActivate() throws" << \
            " javax.ejb.EJBException, java.rmi.RemoteException {}\n\n"

        # ejbLoad
        gencode << "\tpublic void ejbLoad() throws" << \
            "javax.ejb.EJBException, java.rmi.RemoteException {}\n\n"

        # ejbPassivate
        gencode << "'\tpublic void ejbPassivate() throws" << \
            " javax.ejb.EJBException, java.rmi.RemoteException {}\n\n"

        # ejbRemove
        gencode << "\tpublic void ejbRemove() throws" << \
            " javax.ejb.EJBException, java.rmi.RemoteException," << \
            " javax.ejb.RemoveException {}\n\n"

        # ejbStore
        gencode << "\tpublic void ejbStore() throws" << \
            " javax.ejb.EJBException, java.rmi.RemoteException {}\n\n"

        # Entity Context functions
        gencode << "\tpublic void setEntityContext(EntityContext arg1)" << \
            " throws javax.ejb.EJBException, java.rmi.RemoteException {}\n\n"
        gencode << "\tpublic void unsetEntityContext() throws" << \
            " javax.ejb.EJBException, java.rmi.RemoteException {}\n\n"

        # ejbCreate and ejbPostCreate
        tmplist = []
        tmplist1 = []
        tmplist << "\tpublic " << @beanName.capitalize << "PK ejbCreate("
        tmplist1 << "\tpublic void ejbPostCreate("

        @numFields.times do |num|
            name = @nameList[num]
            type = @typeList[num]

            tmplist << type << " " << name
            tmplist1 << type << " " << name

            if num < @numFields-1
                tmplist << ", "
                tmplist1 << ", "
            end
        end
            
        tmplist << ") {\n"
        tmplist1 << ") {\n"

        @numFields.times do |num|
            name = @nameList[num]
            tmplist << "\t\tthis." << name << " = " << name << ";\n"
        end
        tmplist << "\n\t\treturn null;\n\t}\n\n"

        gencode += tmplist += tmplist1

        # Accessors and mutators
        @numFields.times do |num|
            name = @nameList[num]
            type = @typeList[num]
            
            gencode << "\tpublic " << type << " get" << name.capitalize << \
                "() {\n"
            gencode << "\t\treturn this." << name << ";\n\t}\n\n"
            gencode << "\tpublic void set" << name.capitalize << "(" << \
                type << " " << name << ") {\n"
            gencode << "\t\tthis." << name << " = " << name << ";\n\t}\n\n"
        end

        gencode << "}\n"

        writeCode(gencode, filename)
    end

    # Generate PK class
    def generatePkClass
        puts "Generating PK class ..."

        pkclass = @beanName.capitalize + "PK"
        filename = pkclass + ".java"
        gencode = []
        numpk = 0

        # Headers
        gencode << "package " << @pkgInfo.pkgName << ";\n\n"
        gencode << "import java.io.*;\n\n"
        gencode << "public class " << pkclass << " implements " << \
            "java.io.Serializable {\n\n"

        # Data variables
        @numFields.times do |num|
            name = @nameList[num]
            type = @typeList[num]
            ispk = @pkList[num]

            if ispk == true
                numpk += 1
                gencode << "\tpublic " << type << " " << name << ";\n"
            end
        end
        gencode << "\n"
        
        # Default constructor
        gencode << "\tpublic " << pkclass << "() {\n"
        gencode << "\t\tsuper();\n\t}\n\n"

        # Second constructor, accessors, mutators, equals and hashcode function
        gencode << "\tpublic " << pkclass << "("
        tmplist = []
        getterlist = []
        setterlist = []
        equalslist = []
        hashlist = []
        
        equalslist << "\tpublic boolean equals(Object o) {\n"
        equalslist << "\t\t" << pkclass << " oKey = (" << pkclass << ")o;\n\n"
        equalslist << "\t\tif ("
        hashlist << "\tpublic int hashCode() {\n"
        hashlist << "\t\tStringBuffer sb = new StringBuffer();\n"

        @numFields.times do |num|
            name = @nameList[num]
            type = @typeList[num]
            ispk = @pkList[num]
            if ispk == true
                numpk -= 1
                gencode << type << " " << name
                tmplist << "\t\tthis." << name << " = " << name << ";\n"

                getterlist << "\tpublic " << type << " get" << \
                    name.capitalize << "() {\n"
                getterlist << "\t\treturn this." << name << ";\n\t}\n\n"

                setterlist << "\tpublic void set" << name.capitalize << \
                    "(" << type << " " << name << ") {\n"
                setterlist << "\t\tthis." << name << " = " << name << \
                    ";\n\t}\n\n"

                equalslist << "oKey." << name << ".equals(this." << name << \
                    "))"
                hashlist << "\t\tsb.append(this." << name << ".toString());\n"
                
                if numpk > 0
                    gencode << ", "
                    equalslist << " && "
                end
            end
        end

        equalslist << ") {\n\t\t\treturn true;\n\t\t} else {" << 
            "\n\t\t\treturn false;\n\t\t}\n\t}\n\n"
        
        hashlist << "\n\t\tString keys = sb.toString();\n" << \
            "\t\tint hashCode = keys.hashCode();\n" << \
            "\t\treturn hashCode;\n\t}\n\n"
        
        gencode << ") {\n"
        gencode += tmplist
        gencode << "\t}\n\n"
        gencode += getterlist += setterlist += equalslist += hashlist

        # toString function
        gencode << "\tpublic String toString() {" << \
            "\n\t\treturn super.toString();\n\t}\n\n" << "}\n"

        writeCode(gencode, filename)
    end

    # Generate ejb-jar.xml
    def generateEjbJarDotXml
        puts "Generating ejb-jar.xml ..."
        
        homeclass = @pkgInfo.pkgName + "." + @beanName.capitalize + "Home"
        remoteIf = @pkgInfo.pkgName + "." + @beanName.capitalize
        beanclass = @pkgInfo.pkgName + "." + @beanName.capitalize + "Bean"
        pkclass = @pkgInfo.pkgName + "." + @beanName.capitalize + "PK"

        # Change to the meta-inf directory
        Dir.chdir(@metainfPath)
        filename = "ejb-jar.xml"
        gencode = []

        # Headers
        gencode << "<?xml version=\"1.0\"?>\n" << \
            "<!DOCTYPE ejb-jar PUBLIC " << \
            "'-//Sun Microsystems, Inc.//DTD Enterprise JavaBeans 1.1//EN'" <<\
            "'http://java.sun.com/j2ee/dtds/ejb-jar_1_1.dtd'>\n" << \
            "<ejb-jar>\n" << \
            "\t<enterprise-beans>\n" << \
            "\t\t<entity>\n" << \
            "\t\t\t<ejb-name>" << @beanName << "</ejb-name>\n" << \
            "\t\t\t<home>" << homeclass << "</home>\n" << \
            "\t\t\t<remote>" << remoteIf << "</remote>\n" << \
            "\t\t\t<ejb-class>" << beanclass << "</ejb-class>\n" << \
            "\t\t\t<persistence-type>Container</persistence-type>\n" << \
            "\t\t\t<prim-key-class>" << pkclass << "</prim-key-class>\n" << \
            "\t\t\t<reentrant>False</reentrant>\n"
        
        @numFields.times do |num|
            name = @nameList[num]
            gencode << "\t\t\t<cmp-field>\n" << \
                "\t\t\t\t<field-name>" << name << "</field-name>\n" << \
                "\t\t\t</cmp-field>\n" 
        end
        
        gencode << "\t\t</entity>\n" << \
            "\t</enterprise-beans>\n'" << \
            "\t<assembly-descriptor></assembly-descriptor>\n" << \
            "</ejb-jar>\n"
            
        writeCode(gencode, filename)
    end

    # Generate jaws.xml
    def generateJawsDotXml
        puts "Generating jaws.xml ..."

        # Change to the meta-inf directory
        Dir.chdir(@metainfPath)
        filename = "jaws.xml"
        gencode = []

        gencode << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        gencode << "<jaws>\n"
        gencode << "\t<datasource>java:/SQLServerPool</datasource>\n"
        gencode << "\t<type-mapping>MS SQLSERVER2000</type-mapping>\n"
        gencode << "\t<default-entity>\n"
        gencode << "\t\t<remove-table>false</remove-table>\n"
        gencode << "\t</default-entity>\n"
	    gencode << "\t<type-mappings>\n"
        gencode << "\t\t<type-mapping>\n"
        gencode << "\t\t\t<name>MS SQLSERVER2000</name>\n"
        
        gencode << "\t\t\t<mapping>\n"
	    gencode << "\t\t\t\t<java-type>java.lang.Integer</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>INTEGER</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>INTEGER</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"
        
        gencode << "\t\t\t<mapping>\n"
	    gencode << "\t\t\t\t<java-type>java.lang.Character</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>CHAR</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>CHAR</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.lang.Short</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>SMALLINT</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>SMALLINT</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.lang.Double</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>DOUBLE</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>DOUBLE</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.lang.Long</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>DECIMAL</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>DECIMAL(20)</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"        

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.lang.BigDecimal</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>VARCHAR</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>VARCHAR(256)</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.lang.String</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>VARCHAR</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>VARCHAR(256)</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.lang.Object</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>JAVA_OBJECT</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>IMABE</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t\t<mapping>\n"
	    gencode << "\t\t\t\t<java-type>java.lang.Byte</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>TINYINT</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>TINYINT</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.sql.Timestamp</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>TIMESTAMP</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>TIMESTAMP</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"        

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.sql.Date</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>DATE</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>DATETIME</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.sql.Time</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>TIME</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>DATETIME</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.util.Date</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>DATE</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>DATETIME</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.lang.Boolean</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>BIT</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>BIT</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t\t<mapping>\n"
        gencode << "\t\t\t\t<java-type>java.lang.Float</java-type>\n"
        gencode << "\t\t\t\t<jdbc-type>FLOAT</jdbc-type>\n"
        gencode << "\t\t\t\t<sql-type>FLOAT</sql-type>\n"
        gencode << "\t\t\t</mapping>\n"

        gencode << "\t\t</type-mapping>\n"
        gencode << "\t</type-mappings>\n"
        
        gencode << "\t<enterprise-beans>\n"
        gencode << "\t\t<entity>\n"

        gencode << "\t\t<ejb-name>" << @beanName << "</ejb-name>\n"
        gencode << "\t\t<table-name>" << @beanName.upcase << \
            "</table-name>\n"

        gencode << "\t\t<remove-table>false</remove-table>\n"
        gencode << "\t\t<tuned-updates>true</tuned-updates>\n"
        gencode << "\t\t<read-only>false</read-only>\n"
        gencode << "\t\t<time-out>300</time-out>\n"
        gencode << "\t\t<pk-constraint>false</pk-constraint>\n"
        
        @numFields.times do |num|
            name = @nameList[num]
            gencode << "\t\t<cmp-field>\n"
            gencode << "\t\t\t<field-name>" << name << "</field-name>\n"
            gencode << "\t\t\t<column-name>" << name.upcase << \
                "</column-name>\n"
            gencode << "\t\t</cmp-field>\n"
        end

        gencode << "\t\t<finder>\n"
        gencode << "\t\t\t<name>findAll</name>\n"
        gencode << "\t\t\t<query></query>\n"
        gencode << "\t\t\t<order></order>\n"
        gencode << "\t\t</finder>\n"
        
        gencode << "\t\t<finder>\n"
        gencode << "\t\t\t<name>findByPrimaryKey</name>\n"
        gencode << "\t\t\t<query></query>\n"
        gencode << "\t\t\t<order></order>\n"
        gencode << "\t\t</finder>\n"

        gencode << "\t\t</entity>\n"
        gencode << "\t</enterprise-beans>\n"
        gencode << "</jaws>"

        writeCode(gencode, filename)
    end

    # Generate jboss.xml
    def generateJbossDotXml
        puts "Generating jboss.xml ..."

        # Change to the meta-inf directory
        Dir.chdir(@metainfPath)
        filename = "jboss.xml"
        gencode = []

        gencode << "<?xml version=\"1.0\" encoding=\"Cp1252\"?>\n"
        gencode << "<jboss>\n"
        gencode << "\t<resource-managers />\n"
        gencode << "\t<enterprise-beans>\n"
        gencode << "\t\t<entity>\n"
        gencode << "\t\t\t<ejb-name>" << @beanName << "</ejb-name>\n"
        gencode << "\t\t\t<jndi-name>" << @pkgInfo.pkgName << "/" << \
            @beanName << "</jndi-name>\n"

        gencode << "\t\t\t<configuration-name>Standard CMP EntityBean</configuration-name>\n"
        gencode << "\t\t</entity>\n"
        gencode << "\t\t<secure>false</secure>\n"
        gencode << "\t</enterprise-beans>\n"
        gencode << "\n"
        gencode << "\t<container-configuration configuration-class=\"org.jboss.ejb.deployment.EntityContainerConfiguration\">\n"
        gencode << "\t\t<container-name>Standard CMP EntityBean</container-name>\n"
        gencode << "\t\t<container-invoker>org.jboss.ejb.plugins.jrmp13.server.JRMPContainerInvoker</container-invoker>\n"
        gencode << "\t\t<instance-pool>org.jboss.ejb.plugins.EntityInstancePool</instance-pool>\n"
        gencode << "\t\t<instance-cache>org.jboss.ejb.plugins.NoPassivationEntityInstanceCache</instance-cache>\n"
        gencode << "\t\t<persistence-manager>org.jboss.ejb.plugins.jaws.JAWSPersistenceManager</persistence-manager>\n"
        gencode << "\t\t<transaction-manager>org.jboss.tm.TxManager</transaction-manager>\n"
        gencode << "\t\t<container-invoker-conf>\n"
        gencode << "\t\t\t<Optimized>False</Optimized>\n"
        gencode << "\t\t</container-invoker-conf>\n"
        gencode << "\t\t<container-cache-conf/>\n"
        gencode << "\t\t<container-pool-conf>\n"
        gencode << "\t\t\t<MaximumSize>100</MaximumSize>\n"
        gencode << "\t\t\t<MinimumSize>100</MinimumSize>\n"
        gencode << "\t\t</container-pool-conf>\n"
        gencode << "\t</container-configuration>\n"
        gencode << "</jboss>\n"

        writeCode(gencode, filename)
    end

    # Write generated code to file
    def writeCode(gencode, filename)
        begin
            fout = File.new(filename, File::RDWR|File::CREAT)
            fout << gencode
            fout.close
        rescue
            bye("Cannot open file " + filename)
        end
    end
end

# Parse file function
# Parse the filename and read the variable names and their types in
# separate lists
def parseFile(fileName, varList)
    fin = nil
    begin
        fin = File.new(fileName, "r")
    rescue
        msg = "File " + fileName + " not found"
        bye (msg)
    end

    firstLine = true
    packageInfo = nil
    fin.each do |line|
        if firstLine
            packageInfo = parsePackageInfo(line.chomp)
            firstLine = false
        else
            beanVar = parseLine(line.chomp)
            varList << beanVar
        end
    end
    return packageInfo
end

# Error and exit
def bye(msg)
    puts msg
    exit(1)
end

# Parse package info function
def parsePackageInfo(pkg)
    pkgname = pkg.split[1]
    pkglst = pkgname.split(".")
    pkgInfo = PackageInfo.new(pkgname)
    pkgInfo.pkgLst = pkglst
    return pkgInfo
end

# Parse line function
# Parse a single line, extract the variable name, type and isprimary
# attributes, and return an object of BeanVariable type
def parseLine(line)
    data = line.split
    beanvar = BeanVariable.new(data[0], data[1], data[2].to_i)
    return beanvar
end

# Main function
def main(argv)
    dataFile = argv[0]
    varLst = []
    pkgInfo = parseFile(dataFile, varLst)
    codeGen = CodeGenerator.new(dataFile, pkgInfo, varLst)
    codeGen.generate
end

# Driver - call to main function
main (ARGV)
